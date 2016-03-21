{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "os.jinja2" import os with context %}
{%- from 'macros.jinja2' import manage_pid with context %}
include:
  - apt
{#- include $formula.nrpe here as this is root of all nrpe SLSes,
    there is no nrpe.nrpe to do that as other formulas.
    Although, this looks recursive as apt.nrpe includes nrpe but Salt
    can handle that properly #}
  - apt.nrpe
  - bash
  - bash.nrpe
  - cron
  - cron.nrpe
  - hostname
  - local
{% if salt['pillar.get']('graphite_address', False) %}
  - nrpe.diamond
{% endif %}
  - pip
  - pip.nrpe
  - python.dev
  - rsyslog
  - rsyslog.nrpe
  - ssh.client
  - sudo
  - sudo.nrpe
  - virtualenv
  - virtualenv.nrpe
  - yaml

/etc/nagios/python.yml:
  file:
    - managed
    - template: jinja
    - source: salt://nrpe/python.jinja2
    - user: root
    - group: nagios
    - mode: 440
    - require:
      - group: nagios-nrpe-server

/usr/local/nagios/salt-requirements.txt:
  file:
    - absent

nrpe-virtualenv:
  {# remove system-wide nagiosplugin, only use one in our nrpe-virtualenv #}
  pip:
    - removed
    - name: nagiosplugin
    - require:
      - module: pip
  virtualenv:
    - manage
    {#- some check need import salt code #}
    - system_site_packages: True
    - name: /usr/local/nagios
    - require:
      - module: virtualenv
      - pip: nrpe-virtualenv
      - file: /usr/local
    {#- PyYAML needs this pkg for better performance #}
      - pkg: yaml
  file:
    - managed
    - name: {{ opts['cachedir'] }}/pip/nrpe
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://nrpe/requirements.jinja2
    - require:
      - virtualenv: nrpe-virtualenv
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/nagios
    - requirements: {{ opts['cachedir'] }}/pip/nrpe
    - require:
      - virtualenv: nrpe-virtualenv
    - watch:
      - file: nrpe-virtualenv
      - pkg: yaml
      - pkg: python-dev
      - pkg: nagios-nrpe-server

/usr/local/nagios/src:
  file:
    - directory
    - user: root
    - group: root
    - mode: 755
    - require:
      - virtualenv: nrpe-virtualenv

{#- hack for making sure that above virtualenv is used system_site_packages
    this only neccessary for existing virtualenv because the `virtualenv`
    state module does not support that properly #}
/usr/local/nagios/local/lib/python2.7/no-global-site-packages.txt:
  file:
    - absent
    - require:
      - virtualenv: nrpe-virtualenv
    - watch_in:
      - module: nrpe-virtualenv

nagios-plugins:
  pkg:
    - installed
    - pkgs:
      - nagios-plugins-standard
      - nagios-plugins-basic

/etc/nagios/nrpe_local.cfg:
  file:
    - absent

/etc/nagios/nrpe.d/000.nagios.servers.cfg:
  file:
    - absent

{#- old formula cause wrong group, can be removed later #}
/var/lib/nagios:
  file:
    - directory
    - user: root
    - group: nagios
    - require:
      - user: nagios-nrpe-server
      - group: nagios-nrpe-server

nagios-nrpe-server:
{#- all states that require nrpe should require this state or
service: nagios-nrpe-server #}
  pkg:
    - latest
    - require:
      - pkg: nagios-plugins
      - cmd: apt_sources
      - file: bash
  group:
    - present
    - name: nagios
    - require:
      - pkg: nagios-nrpe-server
  user:
    - present
    - name: nagios
    - shell: /bin/false
    - require:
      - pkg: nagios-nrpe-server
  file:
    - managed
    - name: /etc/nagios/nrpe.cfg
    - template: jinja
    - user: root
    - group: nagios
    - mode: 440
    - source: salt://nrpe/server.jinja2
    - require:
      - pkg: nagios-nrpe-server
      - file: /usr/lib/nagios/plugins/check_memory.py
  service:
    - running
    - enable: True
    - order: 50
    - require:
      - file: /etc/nagios/python.yml
    - watch:
      - pkg: nagios-nrpe-server
      - file: nagios-nrpe-server
      - file: /etc/nagios/nrpe_local.cfg
      - file: /etc/nagios/nrpe.d/*
      - file: /var/lib/nagios
{#- PID file owned by root in trusty, no need to manage #}
{%- if os.is_precise %}
  {%- call manage_pid('/var/run/nagios/nrpe.pid', 'nagios', 'nagios', 'nagios-nrpe-server') %}
- pkg: nagios-nrpe-server
  {%- endcall %}
{%- endif %}

{#- Change /usr/local/nagios owner #}
/usr/local/nagios:
  file:
    - directory
    - user: root
    - group: nagios
    - mode: 750
    - require:
      - pkg: nagios-nrpe-server

/usr/local/nagios/bin/passive_check.py:
  file:
    - absent

/usr/lib/nagios/plugins/check_domain.sh:
  file:
    - managed
    - source: salt://nrpe/check_domain.sh
    - user: root
    - group: nagios
    - mode: 550
    - require:
      - module: nrpe-virtualenv

/usr/lib/nagios/plugins/check_memory.py:
  file:
    - managed
    - source: salt://nrpe/check_memory.py
    - user: root
    - group: nagios
    - mode: 550
    - require:
      - pkg: nagios-nrpe-server
      - module: nrpe-virtualenv
      - file: nsca-nrpe
    - require_in:
      - service: nagios-nrpe-server
      - service: nsca_passive

/usr/lib/nagios/plugins/check_oom.py:
  file:
    - managed
    - source: salt://nrpe/check_oom.py
    - user: root
    - group: nagios
    - mode: 550
    - require:
      - pkg: nagios-nrpe-server
      - module: nrpe-virtualenv
      - file: nsca-nrpe
    - require_in:
      - service: nagios-nrpe-server
      - service: nsca_passive

/etc/sudoers.d/nrpe_oom:
  file:
    - managed
    - template: jinja
    - source: salt://nrpe/sudo.jinja2
    - mode: 440
    - user: root
    - group: root
    - require:
      - pkg: sudo
    - require_in:
      - file: nsca-nrpe

/usr/lib/nagios/plugins/check_udp_listen:
  pkg:
    - installed
    - name: iproute  {# for ss #}
  file:
    - managed
    - source: salt://nrpe/check_udp_listen.sh
    - user: root
    - group: nagios
    - mode: 550
    - require:
      - pkg: nagios-nrpe-server
      - module: nrpe-virtualenv
      - file: nsca-nrpe
    - require_in:
      - service: nagios-nrpe-server
      - service: nsca_passive

/etc/nagios/nsca.conf:
  file:
    - absent

/etc/nagios/nsca.d:
  file:
    - directory
    - user: root
    - group: nagios
    - mode: 550
    - require:
      - module: nrpe-virtualenv

/etc/nagios/nsca.yaml:
  file:
    - managed
    - template: jinja
    - source: salt://nrpe/nsca.jinja2
    - user: root
    - group: nagios
    - mode: 440
    - require:
      - module: nrpe-virtualenv
    - context:
        daemon_user: nagios
        daemon_group: nagios

/etc/send_nsca.conf:
  file:
    - absent

/usr/local/nagios/bin/nsca_passive:
  file:
    - managed
    - source: salt://nrpe/nsca_passive.py
    - mode: 500
    - user: root
    - group: nagios
    - require:
      - module: nrpe-virtualenv
      - file: /etc/nagios/nsca.yaml
      - file: /etc/nagios/nsca.d

nsca_passive:
  file:
    - managed
    - name: /etc/init/nsca_passive.conf
    - source: salt://nrpe/upstart.jinja2
    - user: root
    - group: root
    - mode: 400
    - template: jinja
  service:
    - running
    - require:
      - service: rsyslog
      - module: nrpe-virtualenv
      - file: /etc/nagios/python.yml
    - watch:
      - file: nsca_passive
      - file: /usr/local/nagios/bin/nsca_passive
      - module: nrpe-virtualenv
      - file: /etc/nagios/nsca.yaml
      - file: /etc/nagios/nsca.d/*
      - file: hostname

{% from 'nrpe/passive.jinja2' import passive_check with context %}
{{ passive_check('nrpe') }}

{% if not salt['pillar.get']('debug', False) %}
/etc/rsyslog.d/nrpe.conf:
  file:
    - managed
    - template: jinja
    - source: salt://nrpe/rsyslog.jinja2
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: rsyslog
    - watch_in:
      - service: rsyslog
{% endif %}

/etc/cron.hourly/nrpe-killer:
  file:
    - managed
    - source: salt://nrpe/cron_hourly.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 500
    - require:
      - file: bash
      - pkg: cron
      - pkg: nagios-nrpe-server

extend:
{%- from 'macros.jinja2' import change_ssh_key_owner with context %}
{{ change_ssh_key_owner('nagios', {'pkg': 'nagios-nrpe-server'}) }}
