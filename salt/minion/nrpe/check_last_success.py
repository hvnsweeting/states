#!/usr/local/nagios/bin/python2
# {{ salt['pillar.get']('message_do_not_modify') }}
# -*- coding: utf-8 -*-
# Use of this is governed by a license that can be found in doc/license.rst.

'''
Script for checking how long since the last successful calling state.highstate
against a minion.
'''

import datetime
import logging

import salt.config
import salt.loader
import nagiosplugin as nap

from pysc import nrpe

log = logging.getLogger('nagiosplugin.salt.minion.last_success')
TS_KEY = 'returner_timestamps_last_success'


class LastSuccess(nap.Resource):
    def probe(self):
        try:
            # only load config from /etc/salt/minion, not configs in
            # minion.d as that may require higher permission and they are
            # unnecessary for this check
            default_config = salt.config.DEFAULT_MINION_OPTS.update(
                {'default_include': None})
            __opts__ = salt.config.minion_config('/etc/salt/minion',
                                                 defaults=default_config)
            datamod = salt.loader.raw_mod(__opts__, 'data', None)
            ts = datamod['data.get'](TS_KEY)
        except Exception as e:
            log.critical('Cannot get value of %s. Error: %s',
                         TS_KEY, e, exc_info=True)
            raise
        else:
            try:
                hours = (datetime.datetime.now() -
                         datetime.datetime.strptime(
                             ts,
                             "%Y-%m-%dT%H:%M:%S.%f")).total_seconds() / 3600
                ret = [nap.Metric('last_success', hours, min=0,
                                  context='hours')]
                return ret
            except Exception:
                log.critical(('Expected a string presents time in ISO format, '
                              'got %r. If it is None, probably timestamps '
                              'returner has never returned.'),
                             ts)
                raise


def check_last_success(config):
    threshold = '0:%s' % config['max_hours']
    return (
        LastSuccess(),
        nap.ScalarContext('hours', threshold, threshold,
                          fmt_metric='{value} hours ago')
    )


if __name__ == "__main__":
    nrpe.check(check_last_success, {'max_hours': 24})
