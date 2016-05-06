{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set formula = 'sentry' -%}
{%- from 'nrpe/passive.jinja2' import passive_check with context %}
include:
  - cron
  - sentry
  - web
  - apt.nrpe
  - bash.nrpe
  - cron.nrpe
  - memcache.nrpe
  - nginx.nrpe
  - nrpe
  - pip.nrpe
  - postgresql.server.nrpe
  - python.dev.nrpe
  - rsyslog.nrpe
{% if salt['pillar.get']('graphite_address', False) %}
  - statsd.nrpe
{% endif %}
  - redis.nrpe
  - sudo.nrpe
  - uwsgi.nrpe
  - virtualenv.nrpe
{%- if salt['pillar.get'](formula + ':ssl', False) %}
  - ssl.nrpe
{%- endif %}
  - xml.nrpe

{{ passive_check(formula, check_ssl_score=True) }}

extend:
  check_psql_encoding.py:
    file:
      - require:
        - file: nsca-{{ formula }}
  /usr/lib/nagios/plugins/check_pgsql_query.py:
    file:
      - require:
        - file: nsca-{{ formula }}
  /var/lib/deployments/sentry:
    file:
      - group: nagios
      - require:
        - user: nagios-nrpe-server

/var/lib/deployments/sentry/monitoring_dsn:
  file:
    - absent
    - require:
      - file: /usr/lib/nagios/plugins/check_sentry_events.py

{%- set dsn_file = "/var/lib/deployments/sentry/monitoring_dsn.yml" %}
{%- set api_key_file = "/var/lib/deployments/sentry/monitoring_api_key.yml" %}
{#-
the command below will create dsn_file with:
  * user: www-data
  * group: nagios
  * mode: 0400

It will be executed if dsn_file is missing.
#}
sentry_monitoring:
  cmd:
    - script
    - source: salt://sentry/nrpe/sentry_monitoring.py
    - env:
      - SENTRY_CONF: '/etc'
    - args: >
        --dsn-file {{ dsn_file }}
        --api-key-file {{ api_key_file }}
{%- if salt['pillar.get']("__test__", False) %}
        --test
{%- endif %}
    - unless: test -f {{ dsn_file }} && test -f {{ api_key_file }}
    - require:
      - file: /var/lib/deployments/sentry
      - file: sentry-uwsgi
      - module: pysc
      - service: sentry

{{ dsn_file }}:
  file:
    - managed
    - create: False
    - user: www-data
    - group: nagios
    - mode: 440
    - require:
      - cmd: sentry_monitoring
      - user: nagios-nrpe-server
      - user: web

{{ api_key_file }}:
  file:
    - managed
    - create: False
    - user: www-data
    - group: nagios
    - mode: 440
    - require:
      - cmd: sentry_monitoring
      - user: nagios-nrpe-server
      - user: web

/etc/cron.hourly/sentry-monitoring:
  file:
    - absent

/usr/lib/nagios/plugins/check_sentry_events.py:
  file:
    - managed
    - source: salt://sentry/nrpe/check.py
    - user: root
    - group: nagios
    - mode: 550
    - require:
      - file: {{ dsn_file }}
      - file: {{ api_key_file }}
      - module: nrpe-virtualenv
      - pkg: nagios-nrpe-server
    - require_in:
      - service: nagios-nrpe-server
      - service: nsca_passive
