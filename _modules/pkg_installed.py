# -*- coding: utf-8 -*-
# Usage of this is governed by a license that can be found in doc/license.rst.

"""
Module that allow to save the currently installed list of packages and revert
later to that list.
"""

__author__ = 'Bruno Clermont'
__maintainer__ = 'Bruno Clermont'
__email__ = 'bruno@robotinfra.com'

import logging

log = logging.getLogger(__name__)


def __virtual__():
    return 'pkg_installed'


def list_pkgs():
    # for some reasons, if dctrl-tools is installed, salt.modules.apt.list_pkgs
    # return virtual packages as well.
    if __salt__['cmd.has_exec']('grep-available'):
        output = []
        packages = __salt__['pkg.list_pkgs']()
        for pkg_name in packages:
            # virtual packages always have version '1', ignore them
            if packages[pkg_name] != '1':
                output.append(pkg_name)

        output.sort()
        for pkg_name in output:
            log.debug("Installed package: %s", pkg_name)
        return output
    else:
        return __salt__['pkg.list_pkgs']().keys()


def exists():
    '''
    Return True/False if there is a frozen state.
    '''
    try:
        saved = __salt__['data.get'](__virtual__())
        if saved:
            return True
    except KeyError:
        pass
    return False


def forget():
    '''
    Forget any frozen state.
    '''
    log.info("Clear list of installed packages, need to run "
             "``snapshot`` before ``revert``.")
    __salt__['data.update'](__virtual__(), [])


def snapshot():
    '''
    Save the list of installed packages for :func:`revert`
    '''
    installed = list_pkgs()
    msg = "%d saved packages" % len(installed)
    log.debug(msg)
    __salt__['data.update'](__virtual__(), installed)
    return {'name': 'snapshot',
            'changes': {},
            'comment': msg,
            'result': True}


def revert(only_uninstall=False):
    '''
    Take a list of packages, uninstall from the OS packages not in the list
    and install those that are missing.

    If `only_uninstall` is set to ``True``, this will only remove new packages
    and don't install those who disapeared since :func:`snapshot` was executed.
    '''
    ret = {
        'name': 'revert',
        'changes': {},
        'result': True
    }

    try:
        saved = set(__salt__['data.get'](__virtual__()))
        log.debug("Found %d packages", len(saved))
    except KeyError:
        ret['comment'] = "You need to call {0}.snapshot first!".format(
            __virtual__())
        ret['result'] = False
        return ret

    installed_list = list_pkgs()
    installed = set(installed_list)
    install_pkgs = saved - installed
    purge_pkgs = installed - saved

    if not install_pkgs and not purge_pkgs:
        ret['comment'] = "Nothing to change"
        return ret

    if install_pkgs and not only_uninstall:
        ret['comment'] = '%d install %d purge' % (len(install_pkgs),
                                                  len(purge_pkgs))
        ret['changes'].update(__salt__['pkg.install'](pkgs=list(install_pkgs)))
    else:
        ret['comment'] = '%d purge' % len(purge_pkgs)
    if purge_pkgs:
        purge_str = ' '.join(purge_pkgs)
        log.debug("Uninstall: %s", purge_str)
        # until 0.16 is stable, we have to use that dirty trick
        ret['changes']['purged'] = []
        purge_cmd = 'apt-get -q -y --force-yes purge {0}'.format(purge_str)
        out = __salt__['cmd.run_all'](purge_cmd)
        if out['retcode'] != 0:
            ret['result'] = False
            ret['changes']['purged'] = out['stderr']
        else:
            new_pkgs = list_pkgs()
            for pkg in installed_list:
                if pkg not in new_pkgs:
                    ret['changes']['purged'].append(pkg)
        # TODO: the following will be used in 0.16
        # ret['changes']['purged'] = __salt__['pkg.purge'](
        # pkgs=list(purge)))
    return ret
