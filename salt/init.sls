{#- Usage of this is governed by a license that can be found in doc/license.rst

How to create a snapshot of saltstack Ubuntu PPA::

  wget -m -I /saltstack/salt/ubuntu/ \
    http://ppa.launchpad.net/saltstack/salt/ubuntu/
  mv ppa.launchpad.net/saltstack/salt/ubuntu/dists \
    ppa.launchpad.net/saltstack/salt/ubuntu/pool .
  rm -rf ppa.launchpad.net
  find . -type f -name 'index.*' -delete
  find pool/ -type f ! -name '*.deb' -delete

To only keep precise & trusty::

   rm -rf `find dists/ -maxdepth 1 -mindepth 1 ! -name precise ! -name trusty`
   # because some deb can be used for all (E.g: salt-api)
   find pool/ \( -type f -name '*.deb' \( -name '*lucid*' -or  -name '*oneiric*' -or  -name '*quantal*' -or  -name '*raring*' -or -name '*saucy*' \) \) -delete
-#}

include:
  - apt

{%- for i in ('list', 'list.save') %}
salt_absent_old_apt_salt_{{ i }}:
  file:
    - absent
    - name: /etc/apt/sources.list.d/saltstack-salt-{{ grains['oscodename'] }}.{{ i }}
{%- endfor %}

{%- from "macros.jinja2" import salt_version with context %}
{%- set version = salt_version() %}
salt:
  pkg:
    - installed
    - name: salt-common
  pkgrepo:
    - managed
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - name: deb http://repo.saltstack.com/apt/ubuntu/14.04/amd64/2015.8 trusty main
{%- else %}
    - name: deb http://repo.saltstack.com/apt/ubuntu/14.04/amd64/2015.8 trusty main
{%- endif %}
    - file: /etc/apt/sources.list.d/saltstack-salt.list
    - clean_file: True
    - key_url: salt://salt/key.gpg
    - require:
      - cmd: apt_sources
      - file: salt_absent_old_apt_salt_list
      - file: salt_absent_old_apt_salt_list.save
    - require_in:
      - pkg: salt
  cmd: {#- the state which act as an API, consumer only need to watch this if it need to watch changes of this SLS #}
    - wait
    - name: echo "state(s) in ``salt`` have been changed"
    - watch:
      - pkg: salt

/var/cache/salt:
  file:
    - directory
    - user: root
    - group: root
    - mode: 755
