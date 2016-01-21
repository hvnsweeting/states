{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set ssl = salt['pillar.get']('sentry:ssl', False) %}

include:
  - apt
  - bash
  - cron
  - local
  - nginx
  - pip
  - postgresql.server
  - python.dev
  - memcache
  - rsyslog
{% if ssl %}
  - ssl
{% endif %}
{% if salt['pillar.get']('graphite_address', False) %}
  - statsd
{% endif %}
  - redis
  - sudo
  - uwsgi
  - virtualenv
  - web
  - xml

/usr/local/sentry/salt-requirements.txt:
  file:
    - absent

sentry:
  virtualenv:
    - manage
    - name: /usr/local/sentry
    - system_site_packages: False
    - require:
      - module: virtualenv
      - file: /usr/local
  pkg:
    - latest
    - pkgs:
        - libevent-dev
        - libffi-dev
    - require:
      - cmd: apt_sources
  file:
    - managed
    - name: {{ opts['cachedir'] }}/pip/sentry
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://sentry/requirements.jinja2
    - require:
      - virtualenv: sentry
      - pkg: sentry
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/sentry/bin/pip
    - requirements: {{ opts['cachedir'] }}/pip/sentry
    - require:
      - virtualenv: sentry
      - pkg: xml-dev
    - watch:
      - pkg: sentry
      - pkg: python-dev
      - pkg: postgresql-dev
      - file: sentry
    - watch_in:
      - service: memcached
  cmd:
    - wait
    - name: find /usr/local/sentry -name '*.pyc' -delete
    - stateful: False
    - watch:
      - module: sentry
  postgres_user:
    - present
{%- set username = salt['pillar.get']('sentry:db:username', 'sentry') %}
    - name: {{ username }}
    - password: {{ salt['password.pillar']('sentry:db:password', 10) }}
    - runas: postgres
    - require:
      - service: postgresql
  postgres_database:
    - present
    - name: {{ salt['pillar.get']('sentry:db:name', 'sentry') }}
    - owner: {{ username }}
    - runas: postgres
    - require:
      - postgres_user: sentry
      - service: postgresql
  service:
    - running
    - name: sentry-celery
    - enable: True
    - require:
      - file: /var/lib/deployments/sentry
    - watch:
      - cmd: sentry_settings
      - file: /etc/init/sentry-celery.conf
      - file: sentry

/etc/init/sentry-celery.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 400
    - source: salt://sentry/upstart.jinja2
    - require:
      - file: /var/lib/deployments/sentry
      - module: sentry

sentry-uwsgi:
  file:
    - managed
    - name: /etc/uwsgi/sentry.yml
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - source: salt://sentry/uwsgi.jinja2
    - context:
        appname: sentry
        module: sentry.wsgi
        virtualenv: /usr/local/sentry
        chdir: /usr/local/sentry
    - require:
      - service: memcached
      - service: uwsgi
      - service: rsyslog
      - service: redis
  module:
    - wait
    - name: file.touch
    - m_name: /etc/uwsgi/sentry.yml
    - require:
      - file: /etc/uwsgi/sentry.yml
    - watch:
      - file: sentry
      - cmd: sentry_settings
      - file: /var/lib/deployments/sentry

sentry_settings:
  file:
    - managed
    - name: /etc/sentry.conf.py
    - source: salt://sentry/config.jinja2
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - require:
      - user: web
  cmd:
    - wait
    - stateful: False
    - user: www-data
    - group: www-data
    - name: /usr/local/sentry/bin/sentry --config=/etc/sentry.conf.py upgrade --noinput
    - require:
      - cmd: sentry-migrate-fake
      - module: sentry
      - postgres_database: sentry
      - user: web
    - watch:
      - module: sentry
      - file: sentry_settings
    - watch_in:
      - service: memcached

/usr/local/sentry/manage:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 550
    - source: salt://django/manage.jinja2
    - context:
        alternate_admin_cmd: /usr/local/sentry/bin/sentry --config=/etc/sentry.conf.py
        virtualenv: /usr/local/sentry
    - require:
      - virtualenv: sentry
      - pkg: sudo
      - file: bash

sentry-syncdb-all:
  cmd:
    - wait
    - name: /usr/local/sentry/bin/sentry --config=/etc/sentry.conf.py django syncdb --all --noinput
    - stateful: False
    - require:
      - module: sentry
      - file: sentry_settings
      - service: rsyslog
      - service: redis
    - watch:
      - postgres_database: sentry

sentry_admin_user:
  cmd:
    - wait
    - name: /usr/local/sentry/bin/sentry --config=/etc/sentry.conf.py createuser --superuser --email={{ salt['pillar.get']('sentry:initial_admin_user:email') }} --password={{ salt['pillar.get']('sentry:initial_admin_user:password') }}
    - require:
      - cmd: sentry-syncdb-all
    - watch:
      - postgres_database: sentry

sentry-migrate-fake:
  cmd:
    - wait
    - name: /usr/local/sentry/bin/sentry --config=/etc/sentry.conf.py django migrate --fake --noinput
    - stateful: False
    - watch:
      - cmd: sentry-syncdb-all

/etc/nginx/conf.d/sentry.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - source: salt://sentry/nginx.jinja2
    - context:
        appname: sentry
        root: /usr/local/sentry
    - require:
      - pkg: nginx
      - file: sentry-uwsgi
      - file: /var/lib/deployments/sentry
    - watch_in:
      - service: nginx

/var/lib/deployments/sentry:
    file:
    - directory
    - user: www-data
    - group: www-data
    - mode: 750
    - recurse:
      - user
      - group
    - require:
      - file: web
      - file: sentry-uwsgi

{#-
  can't use module.wait django.collectstatic, sentry.conf.server doesn't
  read /etc/sentry.conf.py
#}
sentry_collectstatic:
  cmd:
    - wait
    - name: /usr/local/sentry/manage django collectstatic --noinput
    - require:
      - cmd: sentry_settings
      - cmd: sentry
      - file: /usr/local/sentry/manage
    - watch:
      - file: sentry_settings
      - module: sentry

{% if ssl %}
extend:
  nginx.conf:
    file:
      - context:
          ssl: {{ ssl }}
  nginx:
    service:
      - watch:
        - cmd: ssl_cert_and_key_for_{{ ssl }}
{% endif %}

{%- set clean_days = salt['pillar.get']('sentry:clean_days', False) %}
/etc/cron.daily/sentry-cleanup:
  file:
{%- if clean_days %}
    - managed
    - user: root
    - group: root
    - mode: 500
    - template: jinja
    - source: salt://sentry/cron_daily.jinja2
    - context:
        clean_days: {{ clean_days }}
    - require:
      - file: bash
      - file: sentry-uwsgi
      - file: sentry_settings
      - pkg: cron
{%- else %}
    - absent
{%- endif %}
