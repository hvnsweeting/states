# -*- coding: utf-8 -*-

# Copyright (c) 2013, Bruno Clermont
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
Module that allow to save the currently installed list of packages and revert
later to that list.
"""

__author__ = 'Bruno Clermont'
__maintainer__ = 'Bruno Clermont'
__email__ = 'patate@fastmail.cn'

import logging

log = logging.getLogger(__name__)

def __virtual__():
    return 'pkg_installed'

def _installed():
    # for some reasons, if dctrl-tools is installed, salt.modules.apt.list_pkgs
    # return virtual packages as well.
    if __salt__['cmd.has_exec']('grep-available'):
        output = []
        packages = __salt__['pkg.list_pkgs']()
        for pkg_name in packages:
            # virtual packages always have version '1', ignore them
            if packages[pkg_name] != '1':
                output.append(pkg_name)
        return output
    else:
        return __salt__['pkg.list_pkgs']().keys()

def exists():
    '''
    Return True/False if there is a frozen state.
    '''
    try:
        saved = __salt__['data.getval'](__virtual__())
        if saved:
            return True
    except KeyError:
        pass
    return False

def forget():
    '''
    Forget any frozen state.
    '''
    __salt__['data.update'](__virtual__(), [])

def snapshot():
    '''
    Save the list of installed packages for :func:`revert`
    '''
    installed = _installed()
    __salt__['data.update'](__virtual__(), installed)
    return {'name': 'snapshot',
            'changes': {},
            'comment': "%d saved packages" % len(installed),
            'result': True}

def revert():
    '''
    Take a list of packages, uninstall from the OS packages not in the list
    and install those that are missing.
    '''
    ret = {
        'name': 'revert',
        'changes': {},
        'result': True
    }

    try:
        saved = set(__salt__['data.getval'](__virtual__()))
        log.debug("Found %d packages", len(saved))
    except KeyError:
        ret['comment'] = "You need to call {0}.snapshot first!".format(
            __virtual__())
        ret['result'] = False
        return ret

    installed_list = _installed()
    installed = set(installed_list)
    install = saved - installed
    purge = installed - saved

    if not install and not purge:
        ret['comment'] = "Nothing to change"
        return ret

    ret['comment'] = '%d install %d purge' % (len(install), len(purge))
    if install:
        ret['changes'].update(__salt__['pkg.install'](pkgs=list(install)))
    if purge:
        # until 0.16 is stable, we have to use that dirty trick
        ret['changes']['purged'] = []
        purge_cmd = 'apt-get -q -y --force-yes purge {0}'.format(
            ' '.join(purge))
        out = __salt__['cmd.run_all'](purge_cmd)
        if out['retcode'] != 0:
            ret['result'] = False
            ret['changes']['purged'] = out['stderr']
        else:
            new_pkgs = _installed()
            for pkg in installed_list:
                if pkg not in new_pkgs:
                    ret['changes']['purged'].append(pkg)
        # the following will be used in 0.16
        # ret['changes']['purged'] = __salt__['pkg.purge'](
        # pkgs=list(purge)))
    return ret
