# -*- coding: utf-8 -*-
# Usage of this is governed by a license that can be found in doc/license.rst.

__author__ = 'Bruno Clermont'
__maintainer__ = 'Bruno Clermont'
__email__ = 'bruno@robotinfra.com'

import os
import datetime
import logging

import salt._compat
from salt.ext.six.moves.urllib.parse import urlparse as salt_urlparse

try:
    from IPy import IP
except ImportError:
    pass

logger = logging.getLogger(__name__)


def update():
    '''
    Run a salt function specified in pillar data.
    Pass specified kwargs to it.

    This intead to be used to run arbitrary salt module and any kwargs to work
    around a limitation of salt regarding the scheduler.

    example of pillar data::

        monitoring:
          update:
            - salutil.refresh_pillar
            - state.sls:
                mods: whatever
                test: True

    or::

        monitoring:
           update:
             - state.highstate
    '''
    pillar = __salt__['pillar.get']('monitoring:update', [])
    if not pillar:
        logger.warn("Not pillar key defined, do nothing.")
    else:
        for mod in pillar:
            if isinstance(mod, basestring):
                logger.debug("output of %s: %s", mod, str(__salt__[mod]()))
            elif isinstance(mod, dict):
                func_name = mod.keys()[0]
                logger.debug("output of %s: %s", str(mod),
                             __salt__[func_name](**mod[func_name]))
            else:
                logger.error("Invalid update value %s", str(mod))


def saltenv():
    '''
    Salt Common default saltenv (ie. not specified trough env= kwarg).
    '''

    if __opts__['file_client'] == 'local':
        logger.info("local mode don't support gitfs and multiple branches, "
                    "force to use 'base' environment")
        return 'base'

    logger.debug("file_client not in local mode.")
    output = __salt__['pillar.get']('branch', 'master')
    if output == 'master':
        return 'base'
    return output


def global_roles():
    '''
    Salt Common list of all available roles.
    '''
    output = __salt__['pillar.get']('global_roles', [])
    if output in ('', []):
        output = []

        for role_dir in __salt__['cp.list_master_dirs'](saltenv(), 'roles'):
            # cp.list_master_dirs return 'roles' which is root dir, ignore.
            # only consider sub-directories
            if '/' in role_dir:
                # append the roles/*$rolename*(/other_optional_dir)
                role = role_dir.split('/')[1]
                if role not in output:
                    output.append(role)
    return output


def urlparse(url):
    return salt_urlparse(url)


def day_of_month(days):
    '''
    Return the day of the month in specified number of days.
    Usefull to make sure crontab are in some future time.
    '''
    now = datetime.datetime.now()
    today = now.date()
    delta = datetime.timedelta(days=days)
    future_day = today + delta
    return future_day.day


def nested_dict_iter(d):
    '''
    iterator that return flattened key, value of a dictionnary.
    '''
    stack = d.items()
    while stack:
        k, v = stack.pop()
        if isinstance(v, dict):
            stack.extend(v.iteritems())
        else:
            yield k, v


def unique_hostname(pillar):
    '''
    Loop trough all pillars and return every single hostnames
    '''
    output = []
    for key, values in nested_dict_iter(pillar):
        if key == 'hostnames':
            # is a string
            if not isinstance(values, (tuple, list)):
                if values not in output:
                    output.append(values)
            # is a list or tuple
            else:
                for value in values:
                    if value not in output:
                        output.append(value)
    return output


def iter_to_bullet_list(iterable):
    return os.linesep.join('- {}'.format(item) for item in iterable)


def format_error_msg(iterable, message, sort=True):
    # if there is no error to append to comments, just skip it
    if iterable:
        header = '-' * 10
        return os.linesep.join((
            str(len(iterable)) + ' ' + message,
            header,
            iter_to_bullet_list(sorted(iterable) if sort else iterable)
        ))
    else:
        return ''


def calc_range(subnet):
    # Returns a list of IP addresses of a network
    return IP(subnet, make_net=True)
