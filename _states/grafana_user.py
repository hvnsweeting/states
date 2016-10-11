# -*- coding: utf-8 -*-
'''
Manage Grafana v3.0 user

.. versionadded:: 2016.3.3

.. code-block:: yaml

    grafana:
      version: 3
      admin_username: admin
      address: grafana.example.com
      admin_password: secret_password

.. code-block:: yaml

    Ensure grafana user exists.

    user_sysadmin:
      grafana_user:
        - present
        - name: sysadmin
        - password: mypassword
        - role: Admin
        - display_name: 'Super sysadmin'
        - email: admin@example.com
'''
from __future__ import absolute_import

import logging
import urlparse

import requests

VIEWER = 'Viewer'
logger = logging.getLogger(__name__)


def __virtual__():
    config = __salt__['config.get']('grafana', {})
    for key in 'admin_username', 'admin_password', 'address':
        if key not in config:
            logger.info('not loaded because missing config grafana:%s', key)
            return False
    configured_version = config.get('version', 1)
    if configured_version != 3:
        logger.info('not loaded because this requires grafana:version == 3, '
                    'got %s', configured_version)
        return False
    return True


def _get_api_root_with_basic_auth():
    address = _get_config('address')
    adm_user = _get_config('admin_username')
    adm_password = _get_config('admin_password')

    scheme, domain = address.split('://')
    return '{scheme}://{username}:{password}@{domain}/api/'.format(
            scheme=scheme,
            username=adm_user,
            password=adm_password,
            domain=domain
    )


def _get_config(name):
    return __salt__['config.get']('grafana:' + name)


def _get_endpoint(endpoint):
    return urlparse.urljoin(_get_api_root_with_basic_auth(), endpoint)


def present(name,
            password,
            email,
            role=VIEWER,
            display_name=None,
            ):
    '''
    Ensure that an user is present.

    name
        Login name of the user.

    role
        Which role of this user ? (Admin, Editor, Viewer)

    password
        Password to authenticate

    email
        Email of user

    display_name
        Optional - Name to display on web .
    '''
    ret = {'result': None, 'comment': None, 'changes': None, 'name': name}

    role = role.lower().title()

    # set default value, also allow user to set display_name to empty string
    if display_name is None:
        display_name = name
    data = {'login': name, 'password': password,
            'role': role, 'name': display_name,
            }

    resp = requests.post(
        _get_endpoint('admin/users'),
        json=data,
        timeout=_get_config('timeout') or 3
    )
    if resp.status_code == 200:
        success_msg = resp.json()
        ret['result'] = True
        ret['changes'] = {'old': '', 'new': name}
        ret['comment'] = 'New user {0} has been created with id {1}'.format(
                         name, success_msg['id'])
    elif resp.status_code == 500:
        if _get_user_id(name):
            ret['return'] = True
            ret['comment'] = (
                'User has already existed, no change has been made'
            )
        else:
            ret['return'] = False
            ret['comment'] = 'Failed to create user {0}. Error {1}'.format(
                name, resp.json()
            )
    else:
        # unhandled errors
        ret['return'] = False
        ret['comment'] = 'Error happened, code {0}, content {1}'.format(
            resp.status, resp.text
        )
    return ret


def _get_user_id(username):
    resp = requests.get(_get_endpoint('users'))
    if resp.status_code == 200:
        for userdata in resp.json():
            if username == userdata['login']:
                return userdata['id']
    else:
        logger.error('Cannot get list of users. Error %s', resp.text)
    return False


def absent(name):
    '''
    Ensure that a grafana user is absent.

    name
        Login name of the user.
    '''
    ret = {'name': name, 'result': None, 'comment': None, 'changes': None}
    guid = _get_user_id(name)
    if guid:
        resp = requests.delete(_get_endpoint('admin/users/{0}'.format(guid)))
        if resp.status_code == 200:
            ret['result'] = True
            ret['comment'] = 'Deleted user {0} which has ID {1}'.format(
                name, guid
            )
            ret['changes'] = {'old': name, 'new': ''}
        else:
            ret['result'] = False
            ret['comment'] = 'Failed to remove user {0}. Error {1}'.format(
                name, resp.text
            )
    else:
        ret['result'] = True
        ret['comment'] = 'User {0} does not exist.'.format(name)
    return ret
