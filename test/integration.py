#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Usage of this is governed by a license that can be found in doc/license.rst

"""
Common repository integration tests

These unittest run on the salt master because the SSH server get installed
and uninstall. The only daemon that isn't killed in the process is Salt Minion.

Check file docs/run_tests.rst for details.
"""

__author__ = 'Bruno Clermont'
__maintainer__ = 'Bruno Clermont'
__email__ = 'bruno@robotinfra.com'

import logging
import pwd
import tempfile
import collections
try:
    import unittest2 as unittest
except ImportError:
    import unittest
import socket
import sys
import shutil
import os
try:
    import xmlrunner
except ImportError:
    xmlrunner = None

import yaml

try:
    import psutil
    HAS_PSUTIL = True
except ImportError:
    HAS_PSUTIL = False

# until https://github.com/saltstack/salt/issues/4994 is fixed, logger must
# be configured before importing salt.client
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG,
                    format="%(asctime)s %(name)s (%(module)s.%(funcName)s:"
                           "%(lineno)d) %(message)s")

import salt.client

# global variables
logger = logging.getLogger()
# is a cleanup required before next test
is_clean = False
# has previous cleanup failed
clean_up_failed = False
# list of process before tests ran
process_list = set()
# list of files before tests ran
files_list = set()
# groups list
groups_list = set()
# users list
users_list = set()

unclean = set()

NO_TEST_STRING = '-*- ci-automatic-discovery: off -*-'
IGNORED_RESULTS = ('One or more requisite failed',)


def _get_salt_client(config_file='/root/salt/states/test/minion'):
    opts = salt.config.minion_config(config_file)
    opts['id'] = socket.gethostname()
    caller = salt.client.Caller(mopts=opts)
    return caller.function

client = _get_salt_client()
all_states = client('cp.list_states')
ran_states_cntr = collections.Counter()


def if_change(result):
    """
    Check if changed occured in :func:`test_clean`
    :param result: result from :func:`salt.client.LocalClient.cmd`
    :type result: dict
    :return: True if any change
    :rtype: bool
    """
    for key in result:
        try:
            if result[key]['changes'] != {}:
                return True
        except TypeError:
            raise ValueError(result)
    return False


def tearDownModule():
    client = _get_salt_client()
    global ran_states_cntr
    logger.debug("Running tearDownModule")
    logger.info('COUNTER: Ran totally: %d States',
                (sum(ran_states_cntr.values())))
    logger.info('COUNTER: By state declaration: %s', ran_states_cntr)
    logger.info('COUNTER: size of counter in bytes %d',
                sys.getsizeof(ran_states_cntr))
    client('state.sls', 'test.teardown')


def setUpModule():
    """
    Prepare minion for tests, this is executed only once time.
    """
    client = _get_salt_client()
    logger.debug("Running setUpModule")

    # force HOME to be root directory
    os.environ['HOME'] = pwd.getpwnam('root').pw_dir

    client('saltutil.sync_all')
    client('saltutil.refresh_modules')
    logger.info("Rendering all *.test SLS to quickly find malformed ones")
    for sls in all_states:
        if sls.endswith('.test'):
            try:
                ret = client('state.show_sls', sls)
            except Exception as err:
                logger.error("Catch error: %s", err, exc_info=True)
                raise
            if isinstance(ret, list):
                # if render is okay, it returns dict, else, it returns list
                # of msg error
                raise Exception(ret)

    try:
        if client('pkg_installed.exists'):
            logger.info(
                "pkg_installed snapshot was found, skip setUpModule(). If you "
                "want to repeat the cleanup process, run "
                "'pkg_installed.forget'")
            return
    except KeyError, err:
        logger.debug("Catch error: %s", err, exc_info=True)
        # salt.client.Caller don't refresh the list of available modules
        # after running saltutil.sync_all, exit after doing it.
        client('saltutil.sync_all')
        logger.warning("Please re-execute: '%s'", ' '.join(sys.argv))
        sys.exit(0)

    def check_error(changes):
        """
        Check if any state failed in setUpModule
        """
        if type(changes) != dict:
            raise ValueError(changes)
        try:
            for change in changes:
                if not changes[change]['result']:
                    raise ValueError(changes[change]['comment'])
        except Exception, err:
            logger.error("Catch error: %s", err, exc_info=True)
            raise ValueError("%s: %s" % (err, changes))

    logger.info("Uninstall more packages, with deborphan.")
    ret = client('state.sls', 'test.clean')
    check_error(ret)
    while if_change(ret):
        logger.info("Still more packages to uninstall.")
        ret = client('state.sls', 'test.clean')
        check_error(ret)

    logger.info("Uninstall deborphan.")
    check_error(client('state.sls', 'deborphan.absent'))

    logger.info("Save state of currently installed packages.")
    output = client('pkg_installed.snapshot')

    try:
        if not output['result']:
            raise ValueError(output['comment'])
    except KeyError, err:
        logger.error("Catch error: %s", err, exc_info=True)
        raise ValueError(output)


def parent_process_id(pid):
    """
    Return the parent process id
    """
    status_file = '/proc/%d/status' % pid
    for line in open(status_file).readlines():
        if line.startswith('PPid'):
            return int(line.rstrip(os.linesep).split("\t")[1])
    raise OSError("can't get parent process id of %d" % pid)


def process_ancestors(pid):
    """
    Return the list of all process ancestor (pid).
    """
    output = []
    try:
        parent = parent_process_id(pid)
    except IOError, err:
        logger.debug("Process %d is already dead now", pid)
        raise err
    else:
        try:
            while parent != 0:
                output.append(parent)
                parent = parent_process_id(parent)
        except IOError, err:
            logger.debug("Ancestor %d is now dead", parent)
            raise err
    return output


def list_user_space_processes():
    """
    return all running processes on minion
    """
    client = _get_salt_client()
    result = client('status.procs')
    output = {}

    for pid in result:
        name = result[pid]['cmd']
        # kernel process are like this: [xfs], ignore them
        if name.startswith('['):
            continue
        output[int(pid)] = name
    return output


def list_non_minion_processes(cmd_name='/usr/bin/python /usr/bin/salt-minion'):
    """
    Return the command name of all processes that aren't executed
    by a minion
    """
    procs = list_user_space_processes()
    output = set()
    minion_pids = []

    # list all minions process
    for pid in procs:
        if procs[pid] == cmd_name:
            logger.debug("Found minion pid %d", pid)
            minion_pids.append(pid)
    logger.debug("Found total of %d minions", len(minion_pids))

    for pid in procs:
        try:
            ancestors = process_ancestors(pid)
        except IOError:
            pass
        else:
            run_through_minion = False
            for minion_pid in minion_pids:
                if minion_pid in ancestors:
                    logger.debug("Ignore %d proc %s as it's run by minion %d",
                                 pid, procs[pid], minion_pid)
                    run_through_minion = True
                    break

            if not run_through_minion:
                logger.debug("Running non-minion process %s[%d]", procs[pid],
                             pid)
                output.add(procs[pid])
    logger.debug("Running processes: %s", os.linesep.join(output))
    return output


def get_groups():
    """
    return a set of groups
    """
    client = _get_salt_client()
    return set(group['name'] for group in client('group.getent', True))


def get_users():
    client = _get_salt_client()
    return set(user['name'] for user in client('user.getent'))


def list_system_files(dirs=("/bin", "/etc", "/usr", "/lib", "/sbin", "/var"),
                      ignored=('/var/lib/ucf',
                               '/etc/systemd',
                               '/etc/ssl/certs',
                               '/usr/share/ca-certificate/',
                               '/etc/subgid-',
                               '/etc/subuid-',
                               '/var/lib/apt/lists',
                               '/var/lib/libuuid',
                               '/var/lib/dpkg',
                               '/var/cache/apt',
                               '/var/cache/pip',
                               '/var/backups',
                               '/var/log/upstart/network-interface-',
                               '/var/cache/salt/minion/extrn_files',
                               '/var/cache/salt/minion/doc',
                               '/usr/lib/x86_64-linux-gnu/libfakeroot',
                               '/usr/lib/i386-linux-gnu/libfakeroot',
                               '/var/cache/salt/minion/extrn_files',
                               '/var/cache/salt/minion/')):
    """
    Returns a set of the files present in each of the directories listed.

    Most of the time it will only make sense to be called with absolute paths
    """
    for directory in dirs:
        if os.path.isdir(directory):

            for root, _, files in os.walk(directory):
                for fn in files:
                    filename = os.path.join(root, fn)
                    if not filename.startswith(tuple(ignored)):
                        yield filename
    return


def render_state_template(state):
    """
    Return de-serialized data of specified state name
    """
    tmp = tempfile.NamedTemporaryFile(delete=False)
    tmp.close()
    state_path = state.replace('.', '/')
    for path_template in ('salt://{0}.sls', 'salt://{0}/init.sls'):
        source = path_template.format(state_path)
        client('cp.get_template', source, tmp.name)
        with open(tmp.name) as yaml_fh:
            try:
                data = yaml.safe_load(yaml_fh)
                if data:
                    logger.debug("Found state %s, return dict size %d",
                                 source, len(data))
                    os.unlink(tmp.name)
                    return data
                logger.debug("%s don't seem to exists", source)
            except Exception:
                logger.error("Can't parse YAML %s", source, exc_info=True)
    logger.error("Couldn't get content of %s", state)
    os.unlink(tmp.name)
    return {}


def run_salt_module(module_name, *args, **kwargs):
    try:
        output = client(module_name, *args, **kwargs)
    except Exception as err:
        logger.error("Catch error: %s", err, exc_info=True)
        raise Exception('Module:{0} error: {1}'.format(module_name, err))
    return output


class TestStateMeta(type):
    """
    Metaclass that create all the test_ methods based on
    state files auto-discovery.
    """

    nrpe_test_all_state = 'test.nrpe'

    @classmethod
    def func_name(mcs, state_name):
        return 'test_%s' % state_name.replace('.', '_')

    @classmethod
    def wrap_test_func(mcs, attrs, test_func_name, new_func_name, doc,
                       *args, **kwargs):
        """
        Wrap function ``self.test_func_name`` and put in into ``attrs`` dict
        """
        def output_func(self):
            func = getattr(self, test_func_name)
            logger.debug("Run unit %s", test_func_name)
            func(*args, **kwargs)
        output_func.__name__ = new_func_name.encode("ascii", errors="replace")
        output_func.__doc__ = doc.encode("ascii", errors="replace")
        logger.debug("Add method %s that run self.%s(...)", new_func_name,
                     test_func_name)
        attrs[new_func_name] = output_func

    @classmethod
    def add_test_integration(mcs, attrs, state):
        """
        add test for integration
        """
        state_test, state_diamond, state_nrpe = ('.'.join((state, s)) for s in
                                                 ('test', 'diamond', 'nrpe'))
        states = [state]

        def _add_include_check(state_integration, itype):
            '''
            Check whether a state has diamond and/or NRPE integration,
            If yes, add checks for missing `include` statement in these
            integration.
            '''
            if state_integration in attrs['all_states']:
                logger.debug("State {0} got {1} integration, add check "
                             "for include".format(state, itype))
                doc = ('Check includes for {0} integration for {1}'
                       '').format(itype, state)
                mcs.wrap_test_func(attrs,
                                   'check_integration_include',
                                   mcs.func_name(state_integration +
                                                 '_include'),
                                   doc,
                                   state,
                                   state_integration)
                states.append(state_integration)

        _add_include_check(state_diamond, 'Diamond')
        _add_include_check(state_nrpe, 'NRPE')

        if len(states) > 1:
            logger.debug("State %s got diamond/NRPE integration", state)
            if state_test in attrs['all_states']:
                logger.debug("State %s do have a custom test state, "
                             "don't create automatically one", state)
                mcs.wrap_test_func(attrs, 'top', mcs.func_name(state),
                                   'Test state %s' % state, [state])
            else:
                logger.debug("State %s don't have custom test state", state)
                doc = 'Test states %s and run all NRPE checks after' % \
                      ', '.join(states)
                states.append(mcs.nrpe_test_all_state)
                # add test for the .sls file
                mcs.wrap_test_func(attrs, 'top', mcs.func_name(state),
                                   'Test state %s' % state, [state])
                # and test for SLS file, and all corresponding integrations
                mcs.wrap_test_func(attrs, 'top',
                                   mcs.func_name(state) + '_with_checks',
                                   doc, states)
        else:
            logger.debug("No diamond/NRPE integration for state %s", state)
            mcs.wrap_test_func(attrs, 'top', mcs.func_name(state),
                               'Test state %s' % state, [state])

    def __new__(mcs, name, bases, attrs):
        '''
        Return a class which consist of all needed test state functions
        '''
        global all_states
        # Get all SLSes to test
        attrs['all_states'] = all_states
        # don't play with salt.minion
        salt_minion_states = []
        for state in attrs['all_states']:
            if state.startswith('salt.minion'):
                salt_minion_states.append(state)
        # but still test its diamond and nrpe
        salt_minion_states.remove('salt.minion.nrpe')
        salt_minion_states.remove('salt.minion.diamond')
        logger.debug("Don't run tests for salt minion, as it can interfer: %s",
                     ','.join(salt_minion_states))
        attrs['all_states'] = list(set(attrs['all_states']) -
                                   set(salt_minion_states))

        attrs['absent'] = []

        # map SLSes to test methods then add to this class
        for state in attrs['all_states']:
            if state in ('top', 'overstate'):
                logger.debug("Ignore state %s", state)
            else:
                # skip SLS contains string that indicate NO-TEST
                spath = state.replace('.', '/')
                try:
                    logger.debug(('Trying to get content '
                                  'of salt://{0}.sls').format(spath))
                    content = run_salt_module(
                        'cp.get_file_str',
                        'salt://{0}.sls'.format(spath))
                    # NOTICE if above module running raises an exception,
                    # Salt will log it out. Therefore, no need to worry
                    # about that exception output.
                except Exception as err:
                    logger.debug(('salt://{0}.sls does not exist. '
                                  'Try salt://{0}/init.sls').format(spath))
                    try:
                        content = run_salt_module(
                            'cp.get_file_str',
                            'salt://{0}/init.sls'.format(spath)
                        )
                        logger.debug(('Got content of '
                                      'salt://{0}/init.sls').format(spath))
                    except Exception:
                        raise err
                if NO_TEST_STRING in content:
                    logger.debug('Explicit ignore state %s', state)
                    continue

                # add all other states
                if state.endswith('.absent'):
                    logger.debug("Add test for absent state %s", state)
                    # build a list of all absent states
                    attrs['absent'].append(state)
                    doc = 'Run absent state for %s' % state.replace('.absent',
                                                                    '')
                    # create test_$(SLS_name)_absent
                    mcs.wrap_test_func(attrs, 'top', mcs.func_name(state),
                                       doc, [state])
                else:
                    logger.debug("%s is not an absent state", state)

                    if state.endswith(('.nrpe', '.diamond', '.test')):
                        logger.debug("Add single test for %s", state)
                        mcs.wrap_test_func(attrs, 'top', mcs.func_name(state),
                                           'Run test %s' % state, [state])
                    else:
                        # all remaining SLSes
                        mcs.add_test_integration(attrs, state)

        attrs['absent'].sort()
        return super(TestStateMeta, mcs).__new__(mcs, name, bases, attrs)


class States(unittest.TestCase):
    """
    Common logic to all Integration test class
    """

    __metaclass__ = TestStateMeta

    def _check_same_status(self, original, function, messages):
        """
        Checks that a set of things is invariant between runs. If `original`
        is None, `function` gets called and its return value saved in
        `original`. If not, `function` is called and its result value is
        compared against `original`. If they differ, the test fails.

        :params original: a set or None
        :params function: a function that returns a set or a generator function
        :params messages: a list of 3 strings used for logging.
            - the first element must take an integer and is used when the set
              is first filled in (original is None)
            - the second element must take an integer and is used when the
              current value of `function` is compared to `original`
            - the third value must take a string, and it's used for the failure
              message
        """
        global clean_up_failed
        # check processes
        if not original:
            # function can be a generator function, so get a set of it
            original.update(set(function()))
            logger.debug(messages[0], len(original))
            logger.debug('Stat: size of stored list: %d',
                         sys.getsizeof(original))
        else:
            current = function()
            global unclean
            for i, e in enumerate(current):
                if e not in original:
                    unclean.add(e)

            logger.debug(messages[1], i)

            if unclean:
                clean_up_failed = True
                return messages[2] % os.linesep.join(unclean)
        return ""

    @staticmethod
    def get_rss(top=10):
        """Get processeses with highest memory usages
        """
        procs = []
        if HAS_PSUTIL:
            for p in psutil.process_iter():
                try:
                    if int(psutil.__version__.split('.')[0]) < 2:
                        procs.append({"name": p.name,
                                      "cmdline": p.cmdline,
                                      "memory_percent": p.get_memory_percent(),
                                      })
                    else:
                        procs.append({"name": p.name,
                                      "cmdline": p.cmdline(),
                                      "memory_percent": p.memory_percent(),
                                      })
                except psutil.NoSuchProcess:
                    logger.debug(
                        'Process %s termninated before return info', p.name)
            procs = sorted(procs, key=lambda p: p["memory_percent"],
                           reverse=True)[0:top]
        return procs

    def setUp(self):
        """
        Clean up the minion before each test.
        """

        global is_clean, clean_up_failed, process_list
        global files_list, users_list, groups_list

        if clean_up_failed:
            if os.env.get('FAIL_FAST', True):
                self.skipTest("Previous cleanup failed")
            else:
                logger.debug("Previous cleanup failed, but FAIL_FAST is True,"
                             " keep testing")
        else:
            logger.debug("Go ahead, cleanup never failed before")

        if is_clean:
            logger.debug("Don't cleanup, it's already done")
            return

        try:
            self.sls(self.absent)
        except AssertionError, err:
            clean_up_failed = True
            logger.error("Can't run all .absent: %s", err)
            self.fail(err)

        # Go back on the same installed packages as after :func:`setUpClass`
        logger.info("Unfreeze installed packages")
        try:
            output = client('pkg_installed.revert', True)
        except Exception, err:
            clean_up_failed = True
            logger.error("Catch error: %s", err, exc_info=True)
            self.fail(err)
        else:
            try:
                if not output['result']:
                    clean_up_failed = True
                    self.fail(repr(output))
            except TypeError, err:
                clean_up_failed = True
                logger.error("Catch error: %s", err, exc_info=True)
                self.fail(output)

        clean_up_errors = []
        clean_up_errors.append(
            self._check_same_status(process_list, list_non_minion_processes, [
                "First cleanup, keep list of %d process",
                "Check %d proccess",
                "Process that still run after cleanup: %s"]))
        clean_up_errors.append(
            self._check_same_status(groups_list, get_groups, [
                "First cleanup, keep list of %d groups",
                "Check %d groups",
                "Newly created groups after cleanup: %s"]))
        clean_up_errors.append(
            self._check_same_status(users_list, get_users, [
                "First cleanup, keep list of %d users",
                "Check %d users",
                "Newly created users after cleanup: %s"]))
        clean_up_errors_msg = os.linesep.join([e for e in
                                              clean_up_errors if e])

        if clean_up_errors_msg:
            logger.error(clean_up_errors)
            clean_up_failed = True
            self.fail(clean_up_errors_msg)

        cleanup_files_msg = self._check_same_status(
            files_list,
            list_system_files, [
                "First cleanup, keep list of %d files",
                "Check %d files",
                "Newly created files after cleanup: %s"])

        if cleanup_files_msg:
            logger.error(cleanup_files_msg)

            # attempt to remove files, if okay, just mark this test fail
            # but keep running other test.

            global unclean
            logger.debug('Attempting to remove existing files: %s', unclean)
            for path in unclean:
                try:
                    if os.path.isdir(path):
                        shutil.rmtree(path)
                    else:
                        os.remove(path)
                except Exception as e:
                    logger.debug(
                        'Failed when removing newly created '
                        'files: %s. Sometimes because of the parent '
                        'directory is deleted before the files they contain.',
                        e)

            # check again and recalculate unclean
            self._check_same_status(
                files_list,
                list_system_files, [
                    "First cleanup, keep list of %d files",
                    "Check %d files",
                    "Newly created files after cleanup: %s"])

            clean_up_failed = True if unclean else False
            is_clean = True
            self.fail(cleanup_files_msg)

        is_clean = True
        self.sls(('salt.minion.deps',))

    def sls(self, states):
        """
        Apply specified list of states.
        """
        logger.debug("Run states: %s", ', '.join(states))
        try:
            output = client('state.sls', ','.join(states))
        except Exception, err:
            logger.error("Catch error: %s", err, exc_info=True)
            self.fail('states: %s. error: %s' % ('.'.join(states), err))
        # if it's not a dict, it's an error
        self.assertEqual(type(output), dict, output)

        # check that all state had been executed properly.
        # build a list of comment of all failed state.
        str_errors = ""

        # A sample output:
        #   pkg_|-vim_|-vim_|-latest:
        #     __run_num__: 5
        #     changes: {}
        #     comment: Package vim is already up-to-date.
        #     name: vim
        #     result: true
        global ran_states_cntr

        logger.debug('Processes with high memory usages: %s', self.get_rss())

        ran_states_cntr.update(sid.split('|')[0] for sid in output)
        for state in output:
            if (not output[state]['result'] and
                    output[state]['comment'] not in IGNORED_RESULTS):

                # remove not useful keys
                for key in ('result', '__run_num__'):
                    try:
                        del output[state][key]
                    except KeyError:
                        pass
                for key in ('comment', 'changes'):
                    if key not in output[state]:
                        output[state][key] = \
                            "WARNING: no '%s' in result of '%s'" % (key, state)
                str_errors += os.linesep.join((
                    '',
                    state,
                    '=' * len(state),
                    'name: {0}'.format(output[state].get('name', '')),
                    'comment: {0}'.format(output[state]['comment']),
                    'changes: {0}'.format(output[state]['changes']),
                    ''
                ))

        if str_errors:
            self.fail("Failure to apply states '%s': %s%s" %
                      (','.join(states), os.linesep, str_errors))
        return output

    def top(self, states):
        """
        Somekind of top.sls
        Mostly, just a wrapper around :func:`sls` to specify that the state is
        not clean.

        If all states are .absent, no need to run a cleanup process between
        test units execution.
        """
        global is_clean
        is_clean = True
        for state in states:
            if state not in self.absent:
                logger.debug("state '%s' isn't an absent, mark unclean", state)
                is_clean = False
        if is_clean:
            logger.debug("All %d states (%s) are absent, don't mark unclean",
                         len(states), ','.join(states))
        logger.info("Run top: %s", ', '.join(states))
        self.sls(states)

    def check_integration_include(self, state, integration):
        """
        Check that Integration state (abc.nrpe) include the integration state
        of all state (abc) includes, such as def.nrpe.
        """
        integration_type = integration.split('.')[-1]
        logger.debug("Check integration include for %s (%s)", state,
                     integration_type)

        # list state include
        try:
            state_include = render_state_template(state)['include']
            logger.debug("State %s got %d include(s)", state,
                         len(state_include))
        except KeyError:
            logger.warn("State %s got no include", state)
            state_include = []

        # list integration include
        try:
            integration_include = render_state_template(integration)['include']
            logger.debug("Integration state %s got %d include(s)", integration,
                         len(integration_include))
        except KeyError:
            logger.warn("Integration state %s got no include", integration)
            integration_include = []

        # convert list of ['abc.nrpe, 'def.nrpe'] into ['abc', 'def']
        integration_state_include = []
        integration_suffix = '.' + integration_type
        for include in integration_include:
            integration_state_include.append(
                include.replace(integration_suffix, ''))
        logger.debug("Non-integration include in %s is %s", integration,
                     ','.join(integration_state_include))

        missing = []
        for potential_missing_include_state in set(state_include) - \
                set(integration_state_include):
            state_integration_include = '.'.join((
                potential_missing_include_state, integration_type))
            if state_integration_include in self.all_states:
                missing.append(state_integration_include)
                logger.error("State %s include %s while %s don't include %s",
                             state, potential_missing_include_state,
                             integration, state_integration_include)
            else:
                logger.debug("State %s include %s, but %s don't exists. OK.",
                             state, potential_missing_include_state,
                             state_integration_include)

        if missing:
            self.fail("Integration state %s of %s miss %d include: %s" % (
                      state, integration, len(missing), ','.join(missing)))

    def test_absent(self):
        """
        Just an empty run to test the absent states
        """
        pass

    @classmethod
    def list_tests(cls):
        """
        Display all available tests and what they do.
        """
        for item in dir(cls):
            if item.startswith('test_'):
                func = getattr(cls, item)
                print '%s.%s: %s ' % (cls.__name__, item,
                                      func.__doc__.strip())

if __name__ == '__main__':
    if '--list' in sys.argv:
        States.list_tests()
    else:
        if xmlrunner is not None:
            unittest.main(testRunner=xmlrunner.XMLTestRunner(
                output='/root/salt', outsuffix='salt'))
        else:
            unittest.main()
