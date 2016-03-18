# -*- coding: utf-8 -*-
# Usage of this is governed by a license that can be found in doc/license.rst.

__author__ = 'Bruno Clermont'
__maintainer__ = 'Bruno Clermont'
__email__ = 'bruno@robotinfra.com'

import logging
import os
import re
from UserList import UserList
from UserDict import IterableUserDict, UserDict

import yaml

logger = logging.getLogger(__name__)

MINE_DATA_FUNC_NAME = 'monitoring.data'
MINE_DATA_KEY = 'checks'
NSCA_D = '/etc/nagios/nsca.d'


def _yaml(filename):
    with open(filename, 'r') as stream:
        try:
            return yaml.load(stream)
        except Exception, err:
            logger.critical("YAML data from failed to parse for '%s'",
                            filename, exc_info=True)
            stream.seek(0)
            logger.debug("failed YAML content of '%s' is '%s'", filename,
                         stream.read())
            raise err


def list_check_formulas():
    '''
    List all formula that have a monitoring check on this minions.
    '''
    output = []
    logger.debug("Check for yaml file in %s", NSCA_D)
    for filename in __salt__['file.find'](NSCA_D, type='f'):
        basename = os.path.basename(filename)
        output.append(os.path.splitext(basename)[0])
    return output


def load_check(formula, remove_sensitive_data=True):
    '''
    Load monitoring data for a single formula.
    '''
    basename = '%s.yml' % formula
    filename = os.path.join(NSCA_D, basename)
    try:
        check = _yaml(filename)
        # append formula name to check data, use for custom macro in
        # shinken event handler
        salt_env = __salt__['pillar.get']('branch', 'master')
        for data in check.itervalues():
            data['formula'] = formula
            data['salt_env'] = salt_env
        logger.debug("monitoring checks: %s", check)
    except Exception, err:
        logger.error("Can't load '%s': %s", filename, err)
        return {}
    if remove_sensitive_data:
        # Remove the key that hold NRPE command that is executed as
        # check.
        # That must not be copied in salt mine as it's not used by
        # shinken and it might contains sensible information.
        # same with subkey 'context' that hold context passed to NRPE
        # check.
        for subkey in ('command', 'arguments'):
            for key in check:
                try:
                    del check[key][subkey]
                except KeyError:
                    pass
    return check


def list_checks(remove_sensitive_data=True):
    '''
    Return all monitor check data for all formula for this minion.
    '''
    checks = {}
    for formula in list_check_formulas():
        checks.update(load_check(formula, remove_sensitive_data))
    return checks


def list_nrpe_checks():
    output = {}
    all_checks = list_checks(False)
    for check in all_checks:
        if 'command' in all_checks[check]:
            output.update({check: all_checks[check]})
    return output


class _DontExistData(object):
    pass


def get_first_ip(interface, addr_type):
    '''
    Get the first public or private IP of an interface
    If that interface does not exist, grab from all interfaces
    '''
    default_ip = __salt__['network.ip_addrs']()[0]
    try:
        if addr_type == 'public':
            return next(
                (public_ip
                 for public_ip in __salt__['network.ip_addrs'](interface)
                 if not __salt__['network.is_private'](public_ip)),
                default_ip)
        else:
            return next(
                (private_ip
                 for private_ip in __salt__['network.ip_addrs'](interface)
                 if __salt__['network.is_private'](private_ip)),
                default_ip)
    except IndexError:
        return default_ip


def data():
    '''
    Return data specific for this minion required for monitoring.
    '''
    output = {
        'shinken_pollers': __salt__['pillar.get']('shinken_pollers', []),
        'roles': __salt__['pillar.get']('roles', []),
        'checks': list_checks(),
        'monitor': __salt__['pillar.get']('monitor', True),
        'parents': __salt__['pillar.get']('parent_hosts', []),
        'filter': __salt__['pillar.get']('firewall:filter', {})
    }

    if 'availabilityZone' in __salt__['grains.ls']():
        # from ec2_info grains
        output['amazon_ec2'] = {
            'availability_zone': __salt__['grains.get']('availabilityZone'),
            'region':  __salt__['grains.get']('region')
        }

    # figure how monitoring can reach this host
    ip_addrs = __salt__['pillar.get']('ip_addrs', {})
    interface = __salt__['pillar.get']('network_interface', 'eth0')
    if ip_addrs:
        # from pillar data
        output['ip_addrs'] = {
            'public': ip_addrs.get('public',
                                   get_first_ip(interface, 'public')),
            'private': ip_addrs.get('private',
                                    get_first_ip(interface, 'private'))
        }
    elif 'amazon_ec2' in output:
        # if IP not defined, just pick those from EC2
        output['ip_addrs'] = {
            'public': __salt__['grains.get']('public-ipv4'),
            'private': __salt__['grains.get']('privateIp'),
        }
    else:
        # from network interface
        output['ip_addrs'] = {
            'public': get_first_ip(interface, 'public'),
            'private': get_first_ip(interface, 'private')
        }

    # figure how monitoring can reach this host using IPv6
    ip_addrs6 = __salt__['pillar.get']('ip_addrs6', {})
    if ip_addrs6:
        output['ip_addrs6'] = ip_addrs6
    else:
        interface = __salt__['pillar.get']('network_interface', 'eth0')
        valid_ip_addrs6 = [
            ip for ip in __salt__['network.ip_addrs6'](interface=interface)
            if not ip.startswith("fe80")]  # filter out link local
        if len(valid_ip_addrs6) > 0:
            output['ip_addrs6'] = {
                'public': valid_ip_addrs6[0]
            }
            output['ip_addrs6']['private'] = output['ip_addrs6']['public']
        else:
            output['ip_addrs6'] = {'public': None, 'private': None}

    # check monitoring_data pillar for extra values to return
    monitoring_data = __salt__['pillar.get']('monitoring_data', {})
    extra_data = {}
    for key_name in monitoring_data:
        try:
            key_type = monitoring_data[key_name]['type']
        except KeyError:
            logger.error("Missing type for '%s'", key_name)
            continue

        try:
            path = monitoring_data[key_name]['path']
        except KeyError:
            logger.error("Missing path for '%s'", key_name)
            continue

        if key_type == 'keys':
            extra_data[key_name] = __salt__['pillar.get'](path, {}).keys()
        elif key_type == 'value':
            extra_data[key_name] = __salt__['pillar.get'](path)
        elif key_type == 'exists':
            value = __salt__['pillar.get'](path, _DontExistData)
            if value == _DontExistData:
                extra_data[key_name] = False
            else:
                extra_data[key_name] = True
        else:
            logger.error("Unknown key type '%s'", key_type)
    output['extra'] = extra_data

    return output


def run_check(check_name, checks=None):
    '''
    Run a specific nagios check

    CLI Example::

        salt '*' nrpe.run_check <check name>

    '''
    if checks is None:
        checks = list_nrpe_checks()
    logger.debug("Found %d checks", len(checks.keys()))
    ret = {
        'name': check_name,
        'changes': {},
    }

    if check_name not in checks:
        ret['result'] = False
        ret['comment'] = "Can't find check '{0}'".format(check_name)
        return ret

    cmd = checks[check_name]['command']
    if __salt__['pillar.get']('__test__', False):
        # nagios user may not have permission to run sudo with --help
        verbose_cmd = re.sub(r'^sudo\s[^\/]*\/', '/', cmd) + ' --help'
        outputverbose = __salt__['cmd.run_all'](verbose_cmd, runas='nagios')
        if ' -v,' in outputverbose['stdout']:
            # yeah, the check supports verbose, let be verbose
            cmd += ' -vv'

    output = __salt__['cmd.run_all'](cmd, runas='nagios')

    ret['comment'] = "stdout: '{0}' stderr: '{1}'".format(output['stdout'],
                                                          output['stderr'])

    if output['retcode'] == 0 and output['stderr']:
        ret['comment'] += "\nCheck is considered fail cos stderr is not empty"
        ret['result'] = False
        return ret

    ret['result'] = output['retcode'] == 0
    return ret


def run_all_checks(return_only_failure=False):
    '''
    Run all available nagios check, usefull to check if everything is fine
    before monitoring system find it.

    CLI Example::

        salt '*' nrpe.run_all_checks

    '''
    output = {}
    all_checks = list_nrpe_checks()
    for check_name in all_checks:
        check_result = run_check(check_name, all_checks)
        del check_result['changes']
        del check_result['name']
        if return_only_failure:
            if not check_result['result']:
                output[check_name] = check_result
        else:
            output[check_name] = check_result
    return output


class SaltMineCheck(object):
    '''
    Raw check from salt mine ``monitoring.data``.
    '''
    def __init__(self, minion_id, name, data):
        self.minion = minion_id
        self.name = name
        self.data = data
        self.resolved = False

    def __repr__(self):
        return '%s (minion %s) %s' % (self.name, self.minion, repr(self.data))

    def resolve_dependencies(self, existing_resolved):
        '''
        Resolve all dependencies to other checks.
        Replace data['dependencies'] with list of :class:`CheckData`
        '''
        if self.resolved:
            return True

        dep_names = self.data.get('dependencies', ())
        if not dep_names:
            logger.debug("%s: no dependencies required", self)
            self.resolved = True
            return True

        logger.debug('%s: %d dependencies', self, len(dep_names))
        deps = []
        try:
            for dep_name in dep_names:
                try:
                    deps.append(existing_resolved.get_minion_check(
                                self.minion, dep_name))
                except (KeyError, IndexError):
                    logger.debug("%s: dependency of %s don't exist.", self,
                                 dep_name)
                    raise
        except (KeyError, IndexError):
            logger.debug("Can't resolve all dependencies of %s, skip.", self)
            return False

        self.resolved = True
        self.data['dependencies'] = deps
        return True


class CheckData(UserDict):
    '''
    Unique monitoring check and it's linked minions.
    Consumed by ``shinken/infra.jinja2``
    '''

    def __init__(self, name, check_list, minions=(), **kwargs):
        self.minions = []
        self.name = name
        self.check_list = check_list
        for minion in minions:
            self.minions.append(minion)
        UserDict.__init__(self, **kwargs)

    def __repr__(self):
        return '%s (%d minions) %s' % (self.name, len(self.minions),
                                       repr(self.data))

    def shinken_service_description(self):
        '''
        Return shinken compatible name. append ``-2``, ``-3`` and so on
        based on different check with same name but different configuration.
        Note: to work at it's best self.check_list should be ``sort()``
        which :func:`shinken` do.
        '''
        check_list_index = self.check_list.index(self)
        if check_list_index > 0:
            return '%s-%d' % (self.name, check_list_index + 1)
        return self.name


class Check(UserList):
    '''
    List of :class:`CheckData`
    '''

    def __init__(self, name, *args, **kwargs):
        self.name = name
        UserList.__init__(self, *args, **kwargs)

    def __repr__(self):
        return ' '.join((self.name, repr(self.data)))

    def minion_index(self, minion):
        for check_data in self:
            if minion in check_data.minions:
                return self.index(check_data)
        raise IndexError("No CheckData with minion %s" % minion)

    def check_index(self, salt_mine_check):
        '''
        Return index in the list of an existing :class:`CheckData`.
        '''
        for check_data in self:
            if salt_mine_check.data == check_data.data:
                return self.index(check_data)
        raise IndexError("No existing check for %s" % salt_mine_check)

    def check_append(self, salt_mine_check):
        '''
        Append to it's appropriate :class:`CheckData` a :class:`SaltMineCheck`
        minion.
        '''
        if not salt_mine_check.resolved:
            raise ValueError("Can't check_append unresolved %s",
                             salt_mine_check)
        try:
            index = self.check_index(salt_mine_check)
            check = self[index]
        except IndexError:
            check = CheckData(salt_mine_check.name, self,
                              dict=salt_mine_check.data)
            self.append(check)
        check.minions.append(salt_mine_check.minion)

    def sort(self, *args, **kwds):
        # reverse sort by number of minions, more = first in list
        self.data.sort(cmp=lambda y, x: cmp(len(x.minions), len(y.minions)))


class Checks(IterableUserDict):

    def get_check_list(self, check_name):
        try:
            return self[check_name]
        except KeyError:
            self[check_name] = Check(check_name)
            logger.debug("Found new check name %s", check_name)
            return self[check_name]

    def get_minion_check(self, minion, check_name):
        check = self[check_name]
        return check[check.minion_index(minion)]

    def process_salt_mine_checks(self, salt_mine_checks):
        '''
        Loop trough a list of :class:`SaltMineCheck`
        remove instance that are all resolved processed.
        '''
        for salt_mine_check in salt_mine_checks:
            if salt_mine_check.resolve_dependencies(self):
                logger.debug("%s all dependencies are ok, process.",
                             salt_mine_check)
                check_list = self.get_check_list(salt_mine_check.name)
                check_list.check_append(salt_mine_check)
                salt_mine_checks.remove(salt_mine_check)


def _flatten_mine_data(mine_data):
    '''
    flatten to a single list all monitor checks for all minions that are
    monitored.
    '''
    output = []
    for minion in mine_data.keys():
        if not mine_data[minion]['monitor']:
            logger.info("Ignore unmonitored minion %s", minion)
        else:
            logger.debug("Monitor minion %s %d checks", minion,
                         len(mine_data[minion][MINE_DATA_KEY]))
            for check_name in mine_data[minion][MINE_DATA_KEY]:
                output.append(SaltMineCheck(minion, check_name,
                              mine_data[minion][MINE_DATA_KEY][check_name]))
    logger.debug("Total of %d checks to process", len(output))
    return output


def shinken(mine_data=None):
    '''
    Pre-process all salt mine monitoring data for all minions to let
    shinken build a monitoring configuration.

    The
    '''
    # which dict key data() put data processed by this function
    if not mine_data:
        mine_data = __salt__['mine.get']('*', MINE_DATA_FUNC_NAME)
    flat = _flatten_mine_data(mine_data)
    del mine_data
    output = Checks()
    # loop trough all flatten checks until it's resolved and processed
    while flat:
        before = len(flat)
        output.process_salt_mine_checks(flat)
        after = len(flat)
        if after == before:
            unresolvable = []
            for check in flat:
                unresolvable.append('%s(%s)' % (check.name, check.minion))
            raise ValueError("Can't resolve all dependencies of: %s" %
                             ','.join(unresolvable))
        elif not after:
            logger.debug("Processed successfully all checks from all minions.")
        else:
            logger.debug("Processed %d salt mine check, %d for next batch",
                         before - after, after)

    # sort all :class:`Check`
    for check_name in output.keys():
        output[check_name].sort()
        for check_data in output[check_name]:
            check_data.minions.sort()
    return output
