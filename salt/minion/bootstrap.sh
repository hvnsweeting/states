#!/bin/bash
# {{ salt['pillar.get']('message_do_not_modify') }}
# Use of this is governed by a license that can be found in doc/license.rst.

set -e

# TODO: rewrite in Python
if [ -d /root/salt/states/salt/minion ]; then
    LOCAL_MODE=1
else
    LOCAL_MODE=0
fi

if [ -z "$1" ]; then
    echo "Usage: bootstrap.sh minion-id"
    exit 1
fi
if [ $LOCAL_MODE -eq 0 ] && [ -z "$2" ]; then
    echo "Usage: bootstrap.sh minion-id master-host-or-addr"
    exit 1
fi

# some modules/states require HOME environment variable
# if current HOME is not set to HOME of user who run salt (often is root),
# software may misbehave.

root_home=$(eval echo "~root")
if [ "$HOME" != "$root_home" ]; then
    echo "Current \$HOME set to $HOME. Expected '$root_home'. Please set it correctly (maybe run sudo with -H option)"
    exit 1
fi

apt-get update
apt-get install -y --no-install-recommends python-software-properties python-pip
pip install --upgrade pip==8.1.1
/usr/local/bin/pip install requests==2.4.3 raven==4.1.1 pyyaml==3.12
echo "deb http://archive.robotinfra.com/mirror/salt/2014.7.5+ds-1/ `lsb_release -c -s` main" > /etc/apt/sources.list.d/saltstack-salt-`lsb_release -c -s`.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0E27C0A6
apt-get update
apt-get install -y --force-yes salt-minion
# end of section

if [ $LOCAL_MODE -eq 1 ]; then
    echo "Salt master-less (local) mode"
    if [ ! -f /.dockerinit ]; then
      echo $1 > /etc/hostname
      hostname `cat /etc/hostname`
    fi

    # in local mode create a file_root that only hold a symlink back to
    # salt/master/top.jinja2.
    mkdir -p /root/salt/top
    ln -s /root/salt/states/salt/master/top.jinja2 /root/salt/top/top.sls

    echo """master: 127.0.0.1
id: $1
mysql.default_file: '/etc/mysql/debian.cnf'
file_log_level: debug
file_client: local
file_roots:
  base:
    - /root/salt/states
    - /root/salt/top
pillar_roots:
  base:
    - /root/salt/pillar
mine_functions:
  monitoring.data: []""" > /etc/salt/minion

    salt-call state.sls salt.patch_salt
    restart salt-minion
    salt-call saltutil.sync_all
else
    echo """id: $1
mysql.default_file: '/etc/mysql/debian.cnf'
log_level: debug
master: $2
mine_functions:
  monitoring.data: []""" > /etc/salt/minion
    restart salt-minion
    salt-call state.sls salt.patch_salt
    restart salt-minion
    salt-call saltutil.sync_all
fi
