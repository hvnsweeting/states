{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'nrpe/passive.jinja2' import passive_check with context %}
include:
  - bash
  - bash.nrpe
  - git.nrpe
  - nrpe
  - python.dev.nrpe
  - rsyslog.nrpe
  - sudo
  - sudo.nrpe
  - web
  - xml.nrpe

/etc/sudoers.d/nrpe_uwsgi:
  file:
    - managed
    - template: jinja
    - source: salt://uwsgi/nrpe/sudo.jinja2
    - mode: 440
    - user: root
    - group: root
    - require:
      - pkg: sudo
    - require_in:
      - pkg: nagios-nrpe-server

/usr/lib/nagios/plugins/check_uwsgi_nostderr:
  file:
    - managed
    - template: jinja
    - source: salt://uwsgi/nrpe/nostderr_wrap.jinja2
    - mode: 550
    - user: root
    - group: www-data
    - require:
      - file: /usr/lib/nagios/plugins/check_uwsgi
      - file: /etc/sudoers.d/nrpe_uwsgi

/usr/lib/nagios/plugins/check_uwsgi:
  file:
    - managed
    - template: jinja
    - source: salt://uwsgi/nrpe/check.jinja2
    - mode: 550
    - user: root
    - group: www-data
    - require:
      - module: nrpe-virtualenv
      - user: web
      - file: bash

{%- call passive_check('uwsgi') %}
  - file: /usr/lib/nagios/plugins/check_uwsgi_nostderr
  - file: /etc/sudoers.d/nrpe_uwsgi
{%- endcall %}
