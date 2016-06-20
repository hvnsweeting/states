#!/usr/local/nagios/bin/python
# -*- coding: utf-8 -*-
# Use of this is governed by a license that can be found in doc/license.rst.
"""
NRPE check script that check Jenkins slaves are working or not
"""

__author__ = 'Thanh Nguyen Tuong <thanhnt@unblockapp.com>'
__maintainer__ = 'Thanh Nguyen Tuong <thanhnt@unblockapp.com'
__email__ = 'thanhnt@unblockapp.com'

import logging
import nagiosplugin as nap
import requests

from pysc import nrpe


log = logging.getLogger('nap.jenkins.slaves')


class JenkinsSlaves(nap.Resource):
    def __init__(self, url, username, token):
        self.url = url
        self.username = username
        self.token = token

    def _get_slaves_status(self):
        request_url = '{0}/computer/api/json'.format(self.url)
        resp = requests.get(request_url, auth=(
            self.username, self.token))
        log.info('GET {0}: {1}'.format(request_url, resp.status_code))
        slaves = resp.json()['computer']
        slaves_number = len(slaves)
        log.info('number of slaves is {0}'.format(slaves_number))
        offline_slaves = [slaves[i]['displayName']
                          for i in range(slaves_number)
                          if slaves[i]['offline']]
        log.info('offline slaves: {0}'.format(offline_slaves))
        return (slaves_number, offline_slaves)

    def probe(self):
        log.info('starting to get jenkins slaves...')
        check_result = self._get_slaves_status()
        return [nap.Metric('jenkins slaves', check_result,
                           context='jenkins slaves')]


class SlavesContext(nap.Context):
    def evaluate(self, metric, resource):
        offline_slaves = metric.value[1]
        if len(offline_slaves) > 0:
            state = nap.state.Critical
        else:
            state = nap.state.OK
        return nap.Result(state, metric=metric)


class Summary(nap.Summary):
    def ok(self, results):
        return 'All slaves are working'

    def problem(self, results):
        value = results.results[0].metric.value
        slaves_number, offline_slaves = value
        return "{0}/{1} slaves is/are offline: {2}".format(
            len(offline_slaves), slaves_number, offline_slaves)


def check_jenkins_slaves(config):
    return (JenkinsSlaves(config['url'], config['username'],
                          config['token']),
            SlavesContext('jenkins slaves'),
            Summary()
            )


if __name__ == "__main__":
    nrpe.check(check_jenkins_slaves, {'timeout': 100})
