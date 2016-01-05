# -*- coding: utf-8 -*-
# Use of this is governed by a license that can be found in doc/license.rst.

'''
Get latest build number of given s3 path
'''

__author__ = 'Viet Hung Nguyen <hvn@robotinfra.com>'
__maintainer__ = 'Viet Hung Nguyen <hvn@robotinfra.com>'
__email__ = 'hvn@robotinfra.com'

import logging

logger = logging.getLogger(__name__)

try:
    import boto
    HAS_BOTO = True
except ImportError:
    HAS_BOTO = False

log = logging.getLogger(__name__)
__virtualname__ = 's3archive'


def __virtual__():
    '''
    Only load this module if boto is installed
    '''
    if HAS_BOTO:
        return __virtualname__
    else:
        return False


def latest(bucket, path):
    '''
    Access S3 bucket and find out latest build number
    '''
    try:
        c = boto.connect_s3(__opts__['s3.keyid'], __opts__['s3.key'])
    except KeyError:
        logger.error("s3.keyid and s3.key config in salt minion are required"
                     "for using module %s", __virtualname__)
        raise

    try:
        b = c.get_bucket(bucket)
    except boto.exception.S3ResponseError as e:
            logger.error("Cannot connect to s3,"
                         " please check key/keyid. Error %s", e,
                         exc_info=True)
            raise

    max = 0
    for i in b.list(path):
        try:
            build_number = int(i.name.split('/')[2])
        except IndexError:
            logger.error("Cannot get build number from file path %s", i.name,
                         exc_info=True)
            raise
        else:
            max = max if max > build_number else build_number
    if max == 0:
        raise Exception("Cannot get build number. "
                        "Maybe no file exist or wrong path.")
    return max
