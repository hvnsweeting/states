#!/usr/bin/env python
# -*- coding: utf-8 -*-

__doc__ = '''Script for creating hardlinks in specified directory,
that point to latest files in given directory.
Latest files are base on their nearest modified time (mtime) and grouped
by their facility.
E.g: jenkins-db-2016-06-04-06_27_02.tar.xz -> jenkins-db is facility
NOTE: source_dir and dest_dir must in the same partition or hardlink
will be failed to create. '''

__author__ = 'Viet Hung Nguyen <hvn@unblockapp.com>'
__maintainer__ = 'Viet Hung Nguyen <hvn@unblockapp.com>'
__email__ = 'hvn@unblockapp.com'

import os
import logging

import pysc

logger = logging.getLogger('backup.rotator')


def qualified_files(daily_path, criteria):
    for fn in os.listdir(daily_path):
        fullpath = os.path.join(daily_path, fn)
        passed = True
        for c in criteria:
            if not c(fullpath):
                passed = False
                break
        if passed:
            yield fullpath


def create_hardlink(src_files, dst_dir):
    for src_file in src_files:
        dest_file = os.path.join(dst_dir, os.path.basename(src_file))
        try:
            os.link(src_file, dest_file)
        except OSError as e:
            logger.warn(
                'Cannot create link %s --> %s. Reason: %s.'
                'This might caused by running the script multiple times.',
                dest_file, src_file, e
            )
        logger.debug('Created link: %s --> %s', dest_file, src_file)


def newest_files(files):
    '''
    Get newest files, grouped by their facility.
    '''
    YEAR_INDEX_IN_FILENAME = -4
    latest = {}
    for f in files:
        name_parts = os.path.basename(f).split('-')
        facility = '-'.join(name_parts[:YEAR_INDEX_IN_FILENAME])
        timestamp = os.stat(f).st_mtime
        if facility not in latest or timestamp > latest[facility]['time']:
            latest[facility] = {'path': f, 'time': timestamp}
    for _, data in latest.iteritems():
        yield data['path']


class Rotator(pysc.Application):
    logger = logger

    def get_argument_parser(self):
        argp = super(Rotator, self).get_argument_parser()
        argp.add_argument(
            'source_dir',
            help='source dir for getting list of files to create link'
        )
        argp.add_argument('dest_dir', help='dir to create links')
        return argp

    def main(self):
        criteria = [os.path.isfile]

        logger.info('Getting list of newest backup files in %s',
                    self.config['source_dir'])
        files = newest_files(
            qualified_files(self.config['source_dir'], criteria)
        )
        logger.info('Creating hardlink to dir %s', self.config['dest_dir'])
        try:
            os.mkdir(self.config['dest_dir'])
            logger.info('Created target directory %s as it does not exist',
                        self.config['dest_dir'])
        except OSError:
            pass
        create_hardlink(files, self.config['dest_dir'])


if __name__ == "__main__":
    Rotator().run()
