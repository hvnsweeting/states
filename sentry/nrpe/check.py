#!/usr/local/nagios/bin/python
# -*- coding: utf-8 -*-
# Use of this is governed by a license that can be found in doc/license.rst.

"""
Nagios plugin to check number of events in a graylog2 server
"""

__author__ = 'Diep Pham'
__maintainer__ = 'Diep Pham'
__email__ = 'favadi@robotinfra.com'

import logging
import urlparse

import nagiosplugin
import raven
import requests

from pysc import nrpe, unserialize_yaml

logger = logging.getLogger('sentry.nrpe.check')
# disable warning: InsecureRequestWarning: Unverified HTTPS request is
# being made.
requests.packages.urllib3.disable_warnings()


class EventCountCheck(nagiosplugin.Resource):

    def __init__(self, dsn_file, api_key_file):
        try:
            dsn_loaded = unserialize_yaml(dsn_file, critical=True)
            sentry_dsn = dsn_loaded["dsn"]
            self._sentry_dsn = sentry_dsn
            logger.debug("sentry_dsn: %s", sentry_dsn)
        except IOError as err:
            logger.error(
                "Sentry monitoring DSN file %s does not exist"
                "or is unreadable. Error: %s",
                dsn_file, err)
            raise nagiosplugin.CheckError(
                "Invalid sentry monitoring DSN file: {}".format(dsn_file))

        dsn_parsed = raven.load(sentry_dsn)
        transport_options = dsn_parsed["SENTRY_TRANSPORT_OPTIONS"]
        self._verify_ssl = False if ("verify_ssl" in transport_options
                                     and transport_options["verify_ssl"] == "0"
                                     ) else True

        # API format: GET /api/0/projects/{project_id}/groups/
        server = dsn_parsed["SENTRY_SERVERS"][0]
        project_id = dsn_parsed["SENTRY_PROJECT"]
        parsed = urlparse.urlparse(server)
        self._url = urlparse.urlunparse((
            parsed.scheme,
            parsed.netloc,
            "/api/0/projects/{}/groups/".format(project_id),
            parsed.params,
            parsed.query,
            parsed.fragment,
        ))

        try:
            api_key_loaded = unserialize_yaml(api_key_file, critical=True)
        except IOError as err:
            logger.error(
                "Sentry monitoring web API key file %s does not exist"
                "or is unreadable. Error: %s",
                api_key_file, err)
            raise nagiosplugin.CheckError(
                "Invalid sentry monitoring web API key \
                file: {}".format(api_key_file))
        api_key = api_key_loaded['key']
        self._api_key = api_key

    def probe(self):
        logger.debug("EventCountCheck.probe started")
        # send an event for testing
        dsn = self._sentry_dsn
        if not dsn.startswith("requests+"):
            dsn = "requests+" + dsn
        client = raven.Client(dsn=dsn)
        logger.debug("send monitoring messaage to sentry")
        client.captureMessage("sentry monitoring")

        try:
            r = requests.get(
                self._url, auth=(self._api_key, ''),
                verify=self._verify_ssl)
            data = r.json()
            logger.debug("response: %s", data)

            events = 0
            for group in data:
                events += int(group["count"])
            logger.debug("number of events: %d", events)

            return [
                nagiosplugin.Metric('number_of_events', events, min=0)
            ]

        except requests.ConnectionError as err:
            raise nagiosplugin.CheckError(
                "Could not connect to Sentry: %s", err)


def count_events(config):
    return (
        EventCountCheck(dsn_file=config["dsn_file"],
                        api_key_file=config["api_key_file"]),
        nagiosplugin.ScalarContext("number_of_events", critical="0:"),
    )


if __name__ == '__main__':
    nrpe.check(count_events, {
        "dsn_file": "/var/lib/deployments/sentry/monitoring_dsn.yml",
        "api_key_file": "/var/lib/deployments/sentry/monitoring_api_key.yml"
    })
