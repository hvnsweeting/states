# -*- coding: utf-8 -*-
# Usage of this is governed by a license that can be found in doc/license.rst

"""
Common code for backup file checking nrpe plugins
"""

import datetime
import logging
import re
import nagiosplugin
import pysc

log = logging.getLogger('nagiosplugin.backup.client.base')
CACHE_TIMEOUT = 15


class BackupFile(nagiosplugin.Resource):
    def __init__(self, config, facility):
        log.debug("Reading config file: %s", config)
        self.config = pysc.unserialize_yaml(config)

        self.prefix = self.config['backup']['prefix']

        self.facility = facility

    def probe(self):
        log.debug("BackupFile probe started")
        log.debug("Probe backup for facility: %s", self.facility)

        files = {}
        log.debug("Searching keys with prefix %s", self.prefix)
        for file in self.files():
            key, value = file.items()[0]
            # update this if it's the first time this appears, or if the date
            # is newer
            if (key not in files) or (value['date'] > files[key]['date']):
                log.debug("Adding file to return dict")
                files.update(file)
        log.debug("%s on S3? %s", self.facility,
                  str(not files.get(self.facility, None) is None))

        backup_file = files.get(self.facility, {
            'date': datetime.datetime.fromtimestamp(0),
            'size': 0,
        })

        age_metric = nagiosplugin.Metric(
            'age',
            (datetime.datetime.now() - backup_file['date']).total_seconds() /
            (60*60),
            min=0)
        size_metric = nagiosplugin.Metric('size', backup_file['size'], min=0)

        log.debug("BackupFile.probe finished")
        log.debug("returning age: %s, size: %s", age_metric, size_metric)
        return [age_metric, size_metric]

    def files(self):
        """
        Subclasses must implement this method to create the list of files using
        `make_file(name, size)`
        """
        raise NotImplementedError()

    def make_file(self, filename, size):
        log.debug("Creating file dict for: %s(%sB)", filename, size)
        match = re.match(r'(?P<facility>.+)-(?P<date>[0-9\-_]{19})',
                         filename)
        if match:
            match = match.groupdict()
            log.debug("Key matched regexp, facility: %s, date: %s",
                      match['facility'], match['date'])
            name = match['facility']
            date = datetime.datetime.strptime(match['date'],
                                              "%Y-%m-%d-%H_%M_%S")

            return {
                name: {
                    'name': name,
                    'size': size,
                    'date': date,
                }
            }
        else:
            log.warn("Filename didn't match regexp."
                     "This file shouldn't be here: '%s'", filename)

        return {}


def check_backup(Collector, config):
    return (
        Collector(
            config['config'],
            config['facility'],
        ),
        nagiosplugin.ScalarContext('age',
                                   config['warning'],
                                   config['warning']),
        nagiosplugin.ScalarContext('size', "1:", "1:"),
    )


defaults = {
    'warning': '48',
    'config': '/etc/nagios/backup.yml',
}
