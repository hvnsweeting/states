{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - packages
  - hostname

apt.conf:
  file:
    - managed
    {#- 99 prefix is to make sure the config file is the last one to be
        applied #}
    - name: /etc/apt/apt.conf.d/99local
    - source: salt://apt/config.jinja2
    - user: root
    - group: root
    - mode: 440
    - template: jinja
  {#- N: Ignoring file '20auto-upgrades.ucf-dist' in directory '/etc/apt/apt.conf.d/' as it has an invalid filename extension #}
  cmd:
    - run
    - name: rm -f /etc/apt/apt.conf.d/*.ucf-dist

dpkg.conf:
  file:
    - managed
    - name: /etc/dpkg/dpkg.cfg
    - source: salt://apt/dpkg.jinja2
    - user: root
    - group: root
    - mode: 440
    - template: jinja

{%- set backup = '/etc/apt/sources.list.salt-backup' %}
{%- if salt['file.file_exists'](backup) %}
apt.conf.bak:
  file:
    - rename
    - name: {{ backup }}
    - source: /etc/apt/sources.list
    - require_in:
      - file: apt
{%- endif %}

{#- make sure basic ubuntu keys are there #}
apt-key:
  file:
    - managed
    - name: {{ opts['cachedir'] }}/apt.gpg
    - source: salt://apt/key.gpg
    - user: root
    - group: root
    - mode: 440
  cmd:
    - wait
    - name: apt-key add {{ opts['cachedir'] }}/apt.gpg
    - watch:
      - file: apt-key


{#- /etc/cron.daily/apt needs this dir as it will write state file to it #}
/var/lib/apt/periodic:
  file:
    - directory
    - user: root
    - group: root
    - mode: 755
    - require:
      - cmd: apt

{#- minimum configuration of apt and make sure basic packages required by salt
    to work correctly (mostly for pkgrepo, but that aren't required dependencies
    are installed. #}
apt:
  file:
    - managed
    - name: /etc/apt/sources.list
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - contents: |
        # {{ salt['pillar.get']('message_do_not_modify') }}
        {{ salt['pillar.get']('apt:sources')|indent(8) }}
  {#- handle the case when dpkg is interrupted due to OOM:

      dpkg: unrecoverable fatal error, aborting:
        #012 fork failed: Cannot allocate memory
        #012E: Sub-process /usr/bin/dpkg returned an error code (2)

      salt.loaded.int.module.cmdmod: stderr: E: dpkg was interrupted,
      you must manually run 'dpkg --configure -a' to correct the problem. #}
  cmd:
    - run
    - name: dpkg --configure -a
  module:
    - wait
    - name: pkg.refresh_db
    - watch:
      - file: apt
      - file: apt.conf
    - require:
      - host: hostname
      - file: dpkg.conf
      - cmd: apt-key
      - cmd: apt
      - cmd: apt.conf
{%- set packages_blacklist = salt['pillar.get']('packages:blacklist', []) -%}
{%- set packages_whitelist = salt['pillar.get']('packages:whitelist', []) -%}
{%- if packages_blacklist or packages_whitelist %}
    - require_in:
    {%- if packages_blacklist %}
      - pkg: packages_blacklist
    {%- endif -%}
    {%- if packages_whitelist %}
      - pkg: packages_whitelist
    {%- endif -%}
{%- endif %}

{#- unnecessary pkg on server, which cause high load if use tmux/screen #}
update-notifier-common:
  pkg:
    - purged
    - require:
      - pkg: apt_sources
    - require_in:
      - cmd: apt_sources

{#- `apt-xapian-index` may need a lot of memory to speed up search operation #}
apt-xapian-index:
  pkg:
    - purged
    - require:
      - module: apt
    - require_in:
      - cmd: apt_sources

{#- simple state, just keep the API as others used it #}
apt_sources:
  pkg:
    - installed
    - pkgs:
      - debconf-utils
      - python-apt
      - python-software-properties {# to run pkgrepo with ppa argument #}
    - reload_modules: True
    - require:
      - module: apt
      - file: /var/lib/apt/periodic
  cmd:
    - wait
    - name: touch /etc/apt/sources.list
    - watch:
      - pkg: apt_sources
      - module: apt
{%- if salt['pillar.get']('apt:upgrade', False) %}
  module:
    - run
    - name: pkg.upgrade
    - upgrade: True
    - require:
      - module: apt
    - watch_in:
      - cmd: apt_sources
{%- endif %}
