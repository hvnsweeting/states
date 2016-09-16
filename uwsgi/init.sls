{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{% from 'upstart/rsyslog.jinja2' import manage_upstart_log with context %}
include:
  - git
  - local
  - pip
  - python.dev
  - rsyslog
  - salt.minion.deps
  - web
  - xml

{%- set version = '2.0.13.1' %}

/usr/local/uwsgi-1.9.17.1:
  file:
    - absent

/etc/uwsgi.yml:
  file:
    - managed
    - template: jinja
    - source: salt://uwsgi/config.jinja2
    - mode: 440

uwsgi_build:
  pip:
    - installed
    - name: uwsgi=={{ version }}
    - require:
      - module: pip
      - pkg: python-dev

uwsgi_sockets:
  file:
    - directory
    - name: /var/lib/uwsgi
    - user: www-data
    - group: www-data
    - mode: 770
    - require:
      - user: web
      - pip: uwsgi_build

/etc/uwsgi:
  file:
    - directory
    - user: www-data
    - group: www-data
    - mode: 550
    - require:
      - user: web

{#- uWSGI emperor #}
uwsgi:
  file:
    - managed
    - name: /etc/init/uwsgi.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://uwsgi/upstart.jinja2
  service:
    - running
    - name: uwsgi
    - enable: True
    - require:
      - file: /etc/uwsgi
      - file: uwsgi_sockets
      - service: rsyslog
      - pkg: salt_minion_deps
    - watch:
      - file: uwsgi
      - file: /etc/uwsgi.yml
      - user: web
{#- does not use PID, no need to manage #}

{{ manage_upstart_log('uwsgi') }}
