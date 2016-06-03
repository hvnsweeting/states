# -*- coding: utf-8 -*-
# Usage of this is governed by a license that can be found in doc/license.rst.

"""
Generate random password.
"""

__author__ = 'Viet Hung Nguyen'
__maintainer__ = 'Viet Hung Nguyen'
__email__ = 'hvn@robotinfra.com'

import crypt
import hashlib
import random
import string


def __virtual__():
    return 'password'


def _generate_random_password(length):
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for x in range(length))


def generate(name, length=20):
    '''
    Return a random password for specified placeholder name.

    The minion save it for persistance, unless minion cache is deleted or
    data.clear is executed.

    The password isn't encrypted on disk, it can be shared to other minion
    using publish.publish, if peer communication is configured.

    It's not meant for secure usage. For that use pillar.
    It's primary usage is to generate random password used within a single
    minion for things such as local account used to connect components such as
    monitoring check and database.

    Example, in a pillar file::

      monitoring:

      postgresql:
        monitoring:
          user: zabbix
          password: {{ salt['password.generate']('monitoring_user', 30) }}
    '''
    key_name = '-'.join((__virtual__(), name))
    existing_passwd = __salt__['data.get'](key_name)
    if existing_passwd is None:
        password = _generate_random_password(length)
        __salt__['data.update'](key_name, password)
        return password
    else:
        return existing_passwd


def pillar(pillar_path, length=20):
    '''
    Return a random password if `pillar_path` does not exist.
    '''
    pwd = __salt__['pillar.get'](pillar_path, None)
    if pwd is not None:
        return pwd
    return generate(pillar_path, length)


def encrypt_shadow(unencrypted_password, salt_key=None, hash_type='6'):
    '''
    Encrypt a password consumable by shadow.set_password.

    salt_key: up to 16 characters.
    hash_type::

        ID  | Method
        ---------------------------------------------------------
        1   | MD5
        2a  | Blowfish (not in mainline glibc; added in some
            | Linux distributions)
        5   | SHA-256 (since glibc 2.7)
        6   | SHA-512 (since glibc 2.7)
    '''
    if salt_key is None:
        salt_key = _generate_random_password(16)
    unencrypted_password = str(unencrypted_password)
    return crypt.crypt(unencrypted_password,
                       "$%s$%s%s" % (hash_type, salt_key,
                                     unencrypted_password))


def sha256(data):
    """
    return shasum -a 256 of `data` string
    """
    return hashlib.sha256(str(data)).hexdigest()
