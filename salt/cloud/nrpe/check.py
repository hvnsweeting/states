#!/usr/local/nagios/bin/python
# -*- coding: utf-8 -*-
# {{ salt['pillar.get']('message_do_not_modify') }}
# Use of this is governed by a license that can be found in doc/license.rst.

"""
Nagios plugin to check that saltcloud images are as listed in the cloud.profile
file
"""

__author__ = 'Tomas Neme'
__maintainer__ = 'Viet Hung Nguyen'
__email__ = 'hvn@robotinfra.com'

import logging

import nagiosplugin

from pysc import nrpe

log = logging.getLogger("nagiosplugin.salt.cloud.images")


class Summary(nagiosplugin.Summary):
    def ok(self, results):
        return "ok".join(str(r) for r in results)

    def problem(self, results):
        return ";".join(self.format(result) for result in results)

    def format(self, result):
        value = result.metric.value
        count = len(value)
        msg = "is OK"
        if count > 0:
            msg = "%d missing images [%s]" % (count, ", ".join(value))
        return "{metric}: {msg}".format(metric=result.metric.name, msg=msg)


class MissingImageContext(nagiosplugin.Context):
    def describe(self, metric):
        if len(metric.value) > 0:
            return "%d images missing: [%s]" % (len(metric), ", ".join(metric))
        return "No images missing"

    def evaluate(self, metric, resource):
        if len(metric.value) > 0:
            state = nagiosplugin.state.Critical
        else:
            state = nagiosplugin.state.Ok

        return nagiosplugin.Result(state, metric=metric)


class ImageIds(nagiosplugin.Resource):
    """
    Checks the salt-cloud instances list against cloud.profile
    """
    def __init__(self, salt_cloud_config_file, wanted_slugs):
        log.debug("ImageIds(%s)", salt_cloud_config_file)
        self.cloud_cfg = salt_cloud_config_file
        self.wanted_slugs = wanted_slugs

    def probe(self):
        log.debug("ImageIds.probe started")

        # must import it late or logging won't work, a known-bug of salt
        import salt.cloud
        cloudc = salt.cloud.CloudClient('/etc/salt/cloud')
        all_images = cloudc.list_images()

        profile_list = cloudc.opts['profiles']
        providers = cloudc.opts['providers']

        if not all_images:
            log.error("Can't list any images from providers")
        else:
            log.debug("salt list: %s", all_images)

            ids = set()
            # get the providers and their drivers' names and populate a list of
            # ids
            for prv_id, prv_id_data in providers.iteritems():
                for prv_name, prv_data in prv_id_data.iteritems():
                    a_provider_images = all_images[prv_id][prv_name]
                    for img_id, img in a_provider_images.iteritems():
                        if img['slug'] in self.wanted_slugs:
                            log.info("Newest ID for %s: %s",
                                     img['slug'], img_id)
                    try:
                        ids.update(str(a_provider_images[inst]['id'])
                                   for inst in a_provider_images)
                    except KeyError:
                        # amazon uses key ``imageId``
                        ids.update(str(a_provider_images[inst]['imageId'])
                                   for inst in a_provider_images)

            log.debug("received ids: %s", ids)

            imgs = set(str(prof['image']) for prof in profile_list.values())
            log.debug("profile images: %s", imgs)
            yield nagiosplugin.Metric('missing', imgs - ids)
            log.debug("ImageIds.probe ended")


def check_saltcloud_images(config):
    return (
        ImageIds(config['cloud_config_file'], config['wanted_slugs']),
        MissingImageContext('missing'),
        Summary())


if __name__ == '__main__':
    nrpe.check(check_saltcloud_images, {
        'cloud_config_file': '/etc/salt/cloud',
        'wanted_slugs': ('ubuntu-14-04-x64', 'ubuntu-12-04-x64')
    })
