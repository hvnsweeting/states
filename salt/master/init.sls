{#- Usage of this is governed by a license that can be found in doc/license.rst
Install a Salt Management Master (server).
If you install a salt master from scratch, check and run bootstrap_archive.py
and use it to install the master.
-#}

{%- from 'upstart/rsyslog.jinja2' import manage_upstart_log with context -%}

{%- set use_ext_pillar = salt['pillar.get']('salt_master:pillar:branch', False) and salt['pillar.get']('salt_master:pillar:remote', False) -%}

include:
  - local
  - git
{%- if use_ext_pillar %}
  - pip
{%- endif %}
  - python.dev
  - rsyslog
  - salt
  - ssh.client

{%- for dirname in ('salt', 'reactor') %}
/srv/{{ dirname }}:
  file:
    - directory
    - user: root
    - group: root
    {#- jenkins user needs execute permission on this folder, thus set bit 1 for
        ``other`` #}
    - mode: 551
    - require_in:
      - file: /etc/salt/master
{%- endfor -%}

{%- for dirname in ('create', 'destroy', 'job') %}
/srv/reactor/{{ dirname }}:
  file:
    - directory
    - user: root
    - group: root
    - mode: 550
    - require:
      - file: /srv/reactor
    - require_in:
      - file: /etc/salt/master
{%- endfor %}

/srv/reactor/create/highstate.sls:
  file:
    - managed
    - source: salt://salt/master/highstate.jinja2
    - user: root
    - group: root
    - template: jinja
    - mode: 440
    - require:
      - file: /srv/reactor/create
    - require_in:
      - file: /etc/salt/master

{%- if use_ext_pillar %}
/srv/pillars:
  file:
    - absent

salt-master-requirements:
  file:
    - managed
    - name: {{ opts['cachedir'] }}/pip/salt.master
    - source: salt://salt/master/requirements.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - require:
      - module: pip
  module:
    - wait
    - name: pip.install
    - requirements: {{ opts['cachedir'] }}/pip/salt.master
    - watch:
      - file: salt-master-requirements
      - pkg: python-dev
    - watch_in:
      - service: salt-master
    - require_in:
      - pkg: salt-master
{%- else %}
/srv/pillars:
  file:
    - directory
    - user: root
    - group: root
    - mode: 550
    - require:
      - pkg: salt-master
    - require_in:
      - service: salt-master
{%- endif %}

/srv/salt/top.sls:
  file:
    - managed
    - user: root
    - group: root
    - mode: 440
    - source: salt://salt/master/top.jinja2
    - require:
      - file: /srv/salt

{%- for prefix in ('job_changes', 'event_debug') %}
salt-master-{{ prefix }}.py:
  file:
    - managed
    - name: /usr/local/bin/salt-master-{{ prefix }}.py
    - user: root
    - group: root
    - mode: 550
    - source: salt://salt/master/{{ prefix }}.py
    - require:
      - file: /usr/local
{%- endfor -%}

{%- from "macros.jinja2" import salt_version,salt_deb_version with context %}
{%- set version = salt_version() %}
{%- set pkg_version =  salt_deb_version() %}
{#- check deb filename carefully, number `1` after {1} is added only on 0.17.5-1
    pkg sub-version can be anything #}
{%- set master_path = '{0}/pool/main/s/salt/salt-master_{1}_all.deb'.format(version, pkg_version) %}
/etc/salt/master:
  file:
    - managed
    - source: salt://salt/master/config.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 400
    - require:
      - pkg: salt-master
    - context:
        use_ext_pillar: {{ use_ext_pillar }}
salt-master:
  file:
    - managed
    - name: /etc/init/salt-master.conf
    - template: jinja
    - source: salt://salt/master/upstart.jinja2
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: salt-master
  service:
    - running
    - enable: True
    - order: 90
    - require:
      - service: rsyslog
      - pkg: git
      - file: /var/cache/salt
    - watch:
      - pkg: salt-master
      - file: /etc/salt/master
      - file: salt-master
      - cmd: salt
{#- PID file owned by root, no need to manage #}
  pkg:
    - installed
    - skip_verify: True
    - sources:
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
      - salt-master: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/salt/{{ master_path }}
{%- else %}
      - salt-master: http://archive.robotinfra.com/mirror/salt/{{ master_path }}
{%- endif %}
    - require:
      - cmd: salt
{%- if salt['pkg.version']('salt-master') not in ('', pkg_version) %}
      - pkg: salt_master_old_version

{{ manage_upstart_log('salt-master') }}

salt_master_old_version:
  pkg:
    - removed
    - name: salt-master
{%- endif %}
