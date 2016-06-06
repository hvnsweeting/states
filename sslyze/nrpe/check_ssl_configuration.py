#!/usr/local/nagios/bin/python
# -*- coding: utf-8 -*-
# {{ salt['pillar.get']('message_do_not_modify') }}
# Use of this is governed by a license that can be found in doc/license.rst.

"""
Nagios plugin to check the SSL configuration of a server.
This is calculated based on Qualys Server Rating Guide:
https://www.ssllabs.com/projects/rating-guide/
"""

__author__ = 'Quan Tong Anh'
__maintainer__ = 'Quan Tong Anh'
__email__ = 'quanta@robotinfra.com'

import logging
import socket
import re
from datetime import datetime

import nagiosplugin as nap
from plugins import PluginCertInfo, PluginOpenSSLCipherSuites
from utils.SSLyzeSSLConnection import SSLHandshakeRejected

from pysc import nrpe

log = logging.getLogger('nagiosplugin.salt.master.mine')


class SslConfiguration(nap.Resource):
    def __init__(self, host, port):
        self.host = host
        self.port = port

    def check(self):
        shared_settings = {
            'certinfo': 'basic',
            'starttls': None,
            'resum': True,
            'resum_rate': None,
            'http_get': True,
            'xml_file': None,
            'compression': True,
            'tlsv1': True,
            'targets_in': None,
            'keyform': 1,
            'hsts': None,
            'sslv3': True,
            'sslv2': True,
            'https_tunnel': None,
            'nb_retries': 4,
            'heartbleed': True,
            'sni': self.host,
            'https_tunnel_host': None,
            'regular': False,
            'key': None,
            'reneg': True,
            'tlsv1_2': True,
            'tlsv1_1': True,
            'hide_rejected_ciphers': True,
            'keypass': '',
            'cert': None,
            'certform': 1,
            'timeout': 5,
            'xmpp_to': None
        }

        cert_plugin = PluginCertInfo.PluginCertInfo()
        cert_plugin._shared_settings = shared_settings

        cert_result = None
        excs = set()
        for p in reversed(range(1, 6)):
            target = (self.host, socket.gethostbyname(self.host), self.port, p)
            try:
                cert_result = cert_plugin.process_task(target, 'certinfo',
                                                       'basic')
            except SSLHandshakeRejected as e:
                excs.add(e)
            else:
                break

        if not cert_result:
            log.critical("Failed to get cert result")
            for ex in excs:
                log.critical("Exception: %s", ex)
            if excs:
                raise excs[0]

        is_trusted = 'OK'
        cert_result_list = cert_result.get_txt_result()

        for c in cert_result_list:
            if "Not After" in c:
                not_after = c.split("Not After:")[1].lstrip()
            if "Key Size" in c:
                key_size = c.split(':')[1].lstrip().split()[0]
            if "Hostname Validation" in c:
                hostname_validation = c.split(':')[1].lstrip()
                for i in range(cert_result_list.index(c) + 1,
                               cert_result_list.index(c) + 5):
                    if not (cert_result_list[i].split(':')[1].lstrip()
                            .startswith('OK')):
                        is_trusted = re.split(r':\s{2}',
                                              cert_result_list[i])[1].lstrip()
                        break

        expire_date = datetime.strptime(not_after, "%b %d %H:%M:%S %Y %Z")
        expire_in = expire_date - datetime.now()

        if (hostname_validation.startswith('OK') and expire_in.days > 0
                and is_trusted == 'OK'):
            cipher_plugin = (
                PluginOpenSSLCipherSuites.PluginOpenSSLCipherSuites())
            cipher_plugin._shared_settings = shared_settings

            protocols = ['sslv2', 'sslv3', 'tlsv1', 'tlsv1_1', 'tlsv1_2']

            ciphers = []

            for p in protocols[:]:
                cipher_result = cipher_plugin.process_task(target, p, None)

                for c in cipher_result.get_txt_result():
                    if 'rejected' in c:
                        protocols.remove(p)
                    if 'bits' in c:
                        ciphers.append(c.split()[1])

            worst_protocol = protocols[0]
            best_protocol = protocols[-1]

            protocol_scores = {'sslv2': 0,
                               'sslv3': 80,
                               'tlsv1': 90,
                               'tlsv1_1': 95,
                               'tlsv1_2': 100}

            protocol_score = (protocol_scores[worst_protocol] +
                              protocol_scores[best_protocol]) / 2

            key_scores = {(0, 512): 20, (512, 1024): 40, (1024, 2048): 80,
                          (2048, 4096): 90, (4096, 16384): 100}

            # This must be updated when this one is merged:
            # https://github.com/iSECPartners/sslyze/pull/70
            dh_param_strength = 1024

            for k, v in key_scores.iteritems():
                if (k[0] <= min(int(key_size), dh_param_strength)
                        and min(int(key_size), dh_param_strength) < k[1]):
                    key_score = key_scores[k]
                    break

            weakest_cipher_strength = min(ciphers)
            strongest_cipher_strength = max(ciphers)

            cipher_scores = {(0, 128): 20, (128, 256): 80, (256, 16384): 100}
            for k, v in cipher_scores.iteritems():
                if (k[0] <= int(weakest_cipher_strength)
                        and int(weakest_cipher_strength) < k[1]):
                    weakest_cipher_score = cipher_scores[k]
                    break

            for k, v in cipher_scores.iteritems():
                if (k[0] <= int(strongest_cipher_strength)
                        and int(strongest_cipher_strength) < k[1]):
                    strongest_cipher_score = cipher_scores[k]
                    break

            cipher_score = (weakest_cipher_score + strongest_cipher_score) / 2

            final_score = (protocol_score * 0.3 + key_score * 0.3 +
                           cipher_score * 0.4)
        else:
            final_score = 0
        return (hostname_validation, is_trusted, expire_in.days, final_score)

    def probe(self):
        check_results = self.check()
        hostname_validation = check_results[0]
        is_trusted = check_results[1]
        expire_in_days = check_results[2]
        final_score = check_results[3]

        if final_score > 0:
            return [nap.Metric('sslscore', final_score)]
        elif not hostname_validation.startswith('OK'):
            return [nap.Metric('sslscore', 0, context='serverHostname')]
        elif is_trusted != 'OK':
            return [nap.Metric('sslscore', 0, context='validationResult')]
        elif expire_in_days <= 0:
            return [nap.Metric('sslscore', 0, context='expireInDays')]


class SslSummary(nap.Summary):
    def __init__(self, host, port):
        self.host = host
        self.port = port

    def status_line(self, results):
        ssl_configuration = SslConfiguration(self.host, self.port)
        if results['sslscore'].context.name == 'serverHostname':
            return "sslscore is 0 ({0})".format(ssl_configuration.check()[0])
        elif results['sslscore'].context.name == 'validationResult':
            return "sslscore is 0 ({0})".format(ssl_configuration.check()[1])
        elif results['sslscore'].context.name == 'expireInDays':
            return ("sslscore is 0 (The certificate expired {0} days"
                    "ago)").format(ssl_configuration.check()[2])

    def problem(self, results):
        return self.status_line(results)


def main(config):
    """
    Required configs:

    - host
    """
    kwargs = dict(
        host=config['host'],
        port=config['port']
    )

    return (
        SslConfiguration(**kwargs),
        nap.ScalarContext('sslscore',
                          nap.Range('@65:80'), nap.Range('@0:65')),
        nap.ScalarContext('serverHostname',
                          nap.Range('@65:80'), nap.Range('@0:65')),
        nap.ScalarContext('validationResult',
                          nap.Range('@65:80'), nap.Range('@0:65')),
        nap.ScalarContext('expireInDays',
                          nap.Range('@65:80'), nap.Range('@0:65')),
        SslSummary(**kwargs)
    )


if __name__ == "__main__":
    nrpe.check(main, {
        'port': 443,
        'timeout': 60,
    })
