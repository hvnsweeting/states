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
Handle Debian, Ubuntu and other Debian based distribution APT repositories.
"""

__author__ = 'Bruno Clermont'
__maintainer__ = 'Bruno Clermont'
__email__ = 'patate@fastmail.cn'

import logging
import urlparse
import os

from salt import exceptions, utils

log = logging.getLogger(__name__)


def __virtual__():
    '''
    Verify apt is installed.
    '''
    try:
        utils.check_or_die('apt-key')
        return 'apt_repository'
    except exceptions.CommandNotFoundError:
        return False


def present(address, components, distribution=None, source=False, key_id=None,
            key_server=None, in_sources_list_d=True, filename=None):
    '''
    Manage a APT repository such as an Ubuntu PPA

    .. code-block:: yaml

    rabbitmq-server:
      apt_repository:
        - present
        - address: http://www.rabbitmq.com/debian/
        - components:
          - main
        - distribution: testing
        - key_server: pgp.mit.edu
        - key_id: 056E8E56

    address
        Repository address, usually a HTTP or HTTPs URL

    components
        List of repository components, such as 'main'

    distribution:
        Set this to use a different distribution than the one the host that run
        this state.

    source
        Add source "deb-src" statement? not the default.

    key_id
        GnuPG/PGP key ID used to authenticate packages of this repository.

    key_server
        The address of the PGP key server.
        This argument is ignored if key_id is unset.

    in_sources_list_d
        In many distribution, there is a directory /etc/apt/sources.list.d/
        that is included when you run apt-get command.
        Create a file there instead of change /etc/apt/sources.list
        This is used by default.
    '''
    if distribution is None:
        distribution = __salt__['grains.item']('oscodename')['oscodename']

    if filename is None:
        url = urlparse.urlparse(address)
        if not url.scheme:
            return {'name': address, 'result': False, 'changes': {},
                    'comment': "Invalid address '{0}'".format(address)}
        filename = '-'.join((
            # address without port
            url.netloc.split(':')[0],
            # path with _ instead of /
            url.path.lstrip('/').rstrip('/').replace('/', '_'),
            distribution
        ))

    # deb http://ppa.launchpad.net/mercurial-ppa/releases/ubuntu precise main
    # without the deb
    line_content = [address, distribution]
    line_content.extend(components)

    text = [' '.join(['deb'] + line_content)]
    if source:
        text.append(' '.join(['deb-src'] + line_content))

    if in_sources_list_d:
        data = {
            filename: {
                'file': [
                    'managed',
                    {
                        'name': '/etc/apt/sources.list.d/{0}.list'.format(
                            filename)
                    },
                    {
                        'contents': os.linesep.join(text)
                    },
                    {
                        'makedirs': True
                    }
                ]
            }
        }
    else:
        data = {
            filename: {
                'file': [
                    'append',
                    {
                        'name': '/etc/apt/sources.list'
                    },
                    {
                        'text': text
                    },
                    {
                        'makedirs': True
                    }
                ]
            }
        }

    if key_id:
        add_command = ['apt-key', 'adv', '--recv-keys']
        if key_server:
            add_command.extend(['--keyserver', key_server])
        add_command.extend([key_id])
        data[filename]['cmd'] = [
            'run',
            {'name': ' '.join(add_command)},
            {'unless': 'apt-key list | grep -q {0}'.format(key_id)}
        ]

    output = __salt__['state.high'](data)
    file_result, cmd_result = output.values()

    ret = {
        'name': filename,
        'result': file_result['result'] is True and
                  cmd_result['result'] is True,
        'changes': file_result['changes'],
        'comment': ' and '.join((file_result['comment'], cmd_result['comment']))
    }
    ret['changes'].update(cmd_result['changes'])

    if __opts__['test']:
        ret['result'] = None
    elif ret['result'] and ret['changes']:
        __salt__['pkg.refresh_db']()
    elif not ret['result']:
        log.warning("State failed, don't refresh APT DB.")
    else:
        log.warning("No changes, don't refresh APT DB.")

    return ret


def ubuntu_ppa(user, name, key_id, source=False, distribution=None):
    '''
    Manage an Ubuntu PPA repository

    user
        Launchpad username

    name
        Repository name owned by this user

    key_id
        Launchpad PGP key ID

    source
        Add source "deb-src" statement? not the default.

    distribution:
        Set this to use a different Ubuntu distribution than the host that run
        this state.

    For this PPA: https://launchpad.net/~pitti/+archive/postgresql
    the state must be:

    .. code-block:: yaml

        postgresql:
          apt_repository.ubuntu_ppa:
            - user: pitti
            - name: postgresql
            - key_id: 8683D8A2
    '''
    address = 'http://ppa.launchpad.net/{0}/{1}/ubuntu'.format(user, name)
    filename = '{0}-{1}-{2}'.format(
        user, name,
        __salt__['grains.item']('lsb_distrib_codename')['lsb_distrib_codename']
    )
    return present(address, ('main',), distribution, source, key_id,
                   'keyserver.ubuntu.com', True, filename)
