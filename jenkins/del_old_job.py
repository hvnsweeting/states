#!/usr/bin/env python2
# -*- coding: utf-8 -*-
# Use of this is governed by a license that can be found in doc/license.rst.

'''
Script for deleting old disabled jobs.
A job is considered old if all log files are older than N days.
'''

__author__ = 'Viet Hung Nguyen <hvn@robotinfra.com>'
__maintainer__ = 'Viet Hung Nguyen <hvn@robotinfra.com>'
__email__ = 'hvn@robotinfra.com'

import glob
import logging
import logging.handlers
import os
import time
import xml.etree.ElementTree as ET

import requests

import pysc


log = logging.getLogger(__name__)


def _is_old_job(path, days):
    '''
    '''
    files_olds = {}
    for fn in glob.glob(os.sep.join([path, 'builds', 'last*'])):
        buildpath = os.path.join(path, fn)
        try:
            buildlog = os.path.join(buildpath, 'log')
            mage = time.time() - os.stat(buildlog).st_mtime
        except OSError:
            pass
        else:
            files_olds[buildlog] = False
            if mage > days * 86400:
                files_olds[buildlog] = True
            log.debug('%s is %d days, is%s old.', buildlog, mage/86400,
                      ' ' if files_olds[buildlog] else ' not')

    is_old = all(files_olds.values())
    log.debug(files_olds)
    log.debug('%s is old? %s', path, is_old)
    return is_old


def _is_disabled(jobpath):
    config = os.path.join(jobpath, 'config.xml')
    try:
        tree = ET.parse(config)
        return tree.getroot().find('disabled').text == 'true'
    except IOError as e:
        log.debug('Job config does not exist: %s', e)
        return True
    except Exception as e:
        log.debug('Malformed XML config %s', e)
        return False


def _delete_job(jobname, url, username, token):
    request_url = '{0}/job/{1}/doDelete'.format(
        url,
        jobname,
    )
    out = requests.post(request_url, auth=(username, token))
    log.info('%s: %s', url, out.status_code)


def delete_old_jobs(jobdir, days, url, username, token):
    for jobname in os.listdir(jobdir):
        fullpath = os.path.join(jobdir, jobname)
        if os.path.isdir(fullpath):
            log.debug('Examining %s', fullpath)
            if _is_disabled(fullpath) and _is_old_job(fullpath, days):
                _delete_job(jobname, url, username, token)


class OldJobCleaner(pysc.Application):

    defaults = {"config": "/etc/jenkins/old_jobs.yml"}

    def main(self):
        config = self.config
        delete_old_jobs(
            '/var/lib/jenkins/jobs',
            config["days"], config["url"], config["username"], config["token"])


if __name__ == "__main__":
    OldJobCleaner().run()
