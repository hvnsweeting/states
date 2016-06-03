# -*- coding: utf-8 -*-
# Usage of this is governed by a license that can be found in doc/license.rst.

"""
State for managing nrpe config file from a yaml template
"""

__author__ = 'Viet Hung Nguyen'
__maintainer__ = 'Viet Hung Nguyen'
__email__ = 'hvn@robotinfra.com'

import contextlib
import logging
import os
import time

import salt.utils
import salt.utils.yamlloader as yamlloader


log = logging.getLogger(__name__)


def _error(ret, err_msg):
    '''
    Common function for setting error information for return dicts
    '''
    ret['result'] = False
    ret['comment'] = err_msg
    return ret


def absent(name):
    """
    Make sure a check is not present in the system

    .. warning:: not implemented

    .. todo:: this should remove ``"/etc/nagios/nrpe.d/{0}.cfg".format(name)``
    """


def managed(name, source=None, template='jinja',
            user='root', group='nagios', mode='440',
            context={},
            makedirs=False,
            show_diff=True,
            backup=False,
            dir_mode=755,
            contents=None,
            defaults=None,
            skip_verify=False,
            **kwargs):
    """
    Make sure a monitoring check is present in the system

    .. todo:: document this better
    """

    ret = {'name': name,
           'changes': {},
           'result': True,
           'comment': ''}

    source_hash = ''

    # Retrieve the source file from the server
    name = "/etc/nagios/nrpe.d/{0}.cfg".format(name)
    log.info('Managing %s content from source file %s', name, source)
    try:
        sfn, source_sum, comment_ = __salt__['file.get_managed'](
            name,
            template,
            source,
            source_hash,
            user,
            group,
            mode,
            __env__,
            context,
            defaults,
            skip_verify,
            **kwargs
        )
    except Exception as exc:
        ret['changes'] = {}
        return _error(ret, 'Unable to manage file: {0}'.format(exc))

    # generate nrpe config from rendered yaml file
    log.debug("Parsing yaml file %s from %s", source, sfn)
    with open(sfn) as f:
        try:
            loaded = yamlloader.load(f, Loader=yamlloader.SaltYamlSafeLoader)
        except Exception, err:
            f.seek(0)
            yaml = f.read()
            __salt__['file.remove'](sfn)
            return _error(ret,
                          os.linesep.join((
                              "Content of failed YAML for %s(%s):" % (source,
                                                                      sfn),
                              '-' * 8,
                              str(err),
                              '-' * 8,
                              yaml)))
        else:
            log.debug("Content of %s(%s):%s%s", source, sfn, os.linesep,
                      str(loaded))
    __salt__['file.remove'](sfn)

    lines = []
    if loaded is None:  # config.jinja2 is empty
        loaded = []
    for check_name in loaded:
        if 'command' in loaded[check_name]:
            lines.append("command[{0}]={1}\n".format(
                check_name, loaded[check_name]['command']))
        else:
            log.info(('Check "%s" has no "command" attribute, it maybe a'
                      ' check which performed by Shinken or %s is malformed'),
                     check_name, name)

    tmp = salt.utils.mkstemp(text=True)
    with salt.utils.fopen(tmp, 'w') as tmp_:
        tmp_.writelines(lines)

    if __opts__['test']:
        if salt.utils.istextfile(name):
            with contextlib.nested(
                    salt.utils.fopen(tmp, 'rb'),
                    salt.utils.fopen(name, 'rb')) as (src, name_):
                slines = src.readlines()
                nlines = name_.readlines()
                if ''.join(nlines) == ''.join(slines):
                    ret['comment'] = ('The file {0} is in the '
                                      'correct state').format(name)
                    return ret

        ret['comment'] = 'File {0} is set to be updated'.format(name)
        ret['result'] = None
        return ret

    # we need compare hash of rendered nrpe file against ``name`` file,
    # which managed, so change hash of source with hash of rendered file
    source_sum['hsum'] = __salt__['file.get_hash'](tmp,
                                                   source_sum['hash_type'])

    # manage nrpe config file
    if comment_ and contents is None:
        return _error(ret, comment_)
    else:
        try:
            return __salt__['file.manage_file'](
                name,
                tmp,
                ret,
                source,
                source_sum,
                user,
                group,
                mode,
                __env__,
                backup,
                makedirs,
                template,
                show_diff,
                contents,
                dir_mode)
        except Exception as exc:
            ret['changes'] = {}
            return _error(ret, 'Unable to manage file: {0}'.format(exc))


def run_all_checks(**kwargs):
    '''
    Run all NRPE check, excepted listed.

    :param list exclude: List of check to skip.
    '''
    try:
        exclude = kwargs['exclude']
    except KeyError:
        exclude = []
    ret = {'name': '{0} excluded'.format(len(exclude)), 'result': None,
           'changes': {}, 'comment': ''}

    # check that checks dependencies are valids
    monitoring_data = __salt__['monitoring.data']()
    try:
        __salt__['monitoring.shinken']({__opts__['id']: monitoring_data})
    except ValueError, err:
        log.info("monitoring_data: %s", monitoring_data)
        ret['comment'] = str(err)
        ret['result'] = False
        return ret

    if exclude is None:
        exclude = []

    # all checks without check in exception list
    checks_name = list(set(__salt__['monitoring.list_nrpe_checks']())
                       - set(exclude))

    if __opts__['test']:
        ret['comment'] = 'would have run following checks: {0}'.format(
            ','.join(checks_name)
        )
        return ret

    try:
        time.sleep(kwargs['wait'])
    except KeyError:
        pass

    failed = {}
    for check_name in checks_name:
        output = __salt__['monitoring.run_check'](check_name)
        if not output['result']:
            failed[check_name] = output['comment']
            ret['result'] = False

    if failed:
        ret['comment'] = str(failed)
        ret['result'] = False
        return ret

    ret['result'] = True
    ret['comment'] = 'All checks ran succesfully'
    return ret


def run_check(name, accepted_failure=None, wait=-1):
    '''
    Run a Nagios NRPE check as a test
    '''
    ret = {'name': name, 'result': None, 'changes': {},
           'comment': ''}

    if wait != -1:
        time.sleep(wait)

    if __opts__['test']:
        ret['comment'] = 'Would have run check'
        return ret

    output = __salt__['monitoring.run_check'](name)
    if not output['result']:
        if accepted_failure is not None:
            if accepted_failure in output['comment']:
                ret['result'] = True
                ret['comment'] = 'Check failed as expected'
                return ret
            else:
                # unexpected failure
                return output
        else:
            # failure
            return output

    ret['result'] = True
    ret['comment'] = 'Executed succesfully'
    return ret
