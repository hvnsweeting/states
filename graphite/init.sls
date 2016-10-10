{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set python_version = '%d.%d' % (grains['pythonversion'][0], grains['pythonversion'][1]) %}
{%- set ssl = salt['pillar.get']('graphite:ssl', False) %}

include:
  - apt
  - bash
  - graphite.common
  - local
  - memcache
  - nginx
  - pip
  - postgresql.server
  - python.dev
  - rsyslog
  - statsd
  - sudo
  - uwsgi
  - virtualenv
  - web
{% if ssl %}
  - ssl
{% endif %}

{#graphite_logrotate:#}
{#  file:#}
{#    - managed#}
{#    - name: /etc/logrotate.d/graphite-web#}
{#    - template: jinja#}
{#    - user: root#}
{#    - group: root#}
{#    - mode: 600#}
{#    - source: salt://graphite/logrotate.jinja2#}

graphite_logdir:
  file:
    - directory
    - name: /var/log/graphite/graphite
    - user: www-data
    - group: graphite
    - mode: 770
    - makedirs: True
    - require:
      - user: web
      - user: graphite
      - file: /var/log/graphite

graphite_graph_templates:
  file:
    - managed
    - name: /etc/graphite/graphTemplates.conf
    - template: jinja
    - user: root
    - group: graphite
    - mode: 440
    - source: salt://graphite/graph_templates.jinja2
    - require:
      - user: web
      - user: graphite
      - file: /etc/graphite

graphite_wsgi:
  file:
    - managed
    - name: /usr/local/graphite/lib/python{{ python_version }}/site-packages/graphite/wsgi.py
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 440
    - source: salt://graphite/wsgi.jinja2
    - require:
      - virtualenv: graphite
      - user: web
      - cmd: graphite-web

/usr/local/graphite/manage:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 550
    - source: salt://django/manage.jinja2
    - context:
        settings: graphite.settings
        virtualenv: /usr/local/graphite
    - require:
      - virtualenv: graphite
      - pkg: sudo
      - file: bash

/usr/local/graphite/salt-graphite-requirements.txt:
  file:
    - absent

graphite-web:
  file:
    - managed
    - name: {{ opts['cachedir'] }}/pip/graphite
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://graphite/requirements.jinja2
    - require:
      - virtualenv: graphite
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/graphite/bin/pip
    - requirements: {{ opts['cachedir'] }}/pip/graphite
    - install_options:
      - "--prefix=/usr/local/graphite"
      - "--install-lib=/usr/local/graphite/lib/python{{ python_version }}/site-packages"
    - watch:
      - file: graphite-web
      - pkg: graphite-web
      - pkg: python-dev
      - pkg: postgresql-dev
    - watch_in:
      - service: memcached
  pkg:
    - installed
    - name: libcairo2-dev
    - require:
      - cmd: apt_sources
  cmd:
    - wait
    - name: find /usr/local/graphite -name '*.pyc' -delete
    - stateful: False
    - watch:
      - module: graphite-web
  pip:
    - installed
{%- if salt['pillar.get']('files_archive', False) %}
    - name: django-decorator-include==0.1
{% else %}
    - name: ""
    - editable: git+git://github.com/jeffkistler/django-decorator-include.git#egg=django-decorator-include
{% endif %}
    - bin_env: /usr/local/graphite/bin/pip
    - require:
      - module: graphite-web

graphite-web-uwsgi:
  file:
    - managed
    - name: /etc/uwsgi/graphite.yml
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - source: salt://uwsgi/template.jinja2
    - context:
        appname: graphite
        django_settings: graphite.settings
        module: graphite.wsgi
        uid: www-data
        gid: graphite
        virtualenv: /usr/local/graphite
        chdir: /usr/local/graphite
    - require:
      - module: graphite_initial_fixture
      - service: uwsgi
      - file: graphite_logdir
      - file: /usr/local/graphite/bin/build-index.sh
      - user: web
      - service: rsyslog
      - service: memcached
  module:
    - wait
    - name: file.touch
    - m_name: /etc/uwsgi/graphite.yml
    - watch:
      - file: graphite-web-uwsgi
      - user: graphite
      - module: graphite_settings
      - file: graphite_wsgi
      - file: graphite_graph_templates
      - module: graphite-web
      - cmd: graphite-web
      - file: graphite-urls-patch
      - pip: graphite-web
      - module: graphite_admin_user

graphite-urls-patch:
  file:
    - managed
    - name: /usr/local/graphite/lib/python{{ python_version }}/site-packages/graphite/urls.py
    - source: salt://graphite/urls.jinja2
    - template: jinja
    - user: www-data
    - group: graphite
    - mode: 440
    - require:
      - user: web
      - user: graphite
      - module: graphite-web

graphite_settings:
  file:
    - managed
    - name: /usr/local/graphite/lib/python{{ python_version }}/site-packages/graphite/local_settings.py
    - template: jinja
    - user: www-data
    - group: graphite
    - mode: 440
    - source: salt://graphite/config.jinja2
    - require:
      - user: web
      - user: graphite
      - module: graphite-web
    - watch_in:
      - service: memcached
  postgres_user:
    - present
{%- set username = salt['pillar.get']('graphite:db:username', 'graphite') %}
    - name: {{ username }}
    - password: {{ salt['password.pillar']('graphite:db:password', 10) }}
    - runas: postgres
    - require:
      - service: postgresql
  postgres_database:
    - present
    - name: {{ salt['pillar.get']('graphite:db:name', 'graphite') }}
    - owner: {{ username }}
    - runas: postgres
    - require:
      - postgres_user: graphite_settings
      - service: postgresql
{#    - lc_collate: en_US.UTF-8#}
{#    - lc_ctype: en_US.UTF-8#}
  module:
    - wait
    - name: django.syncdb
    - settings_module: graphite.settings
    - bin_env: /usr/local/graphite
    - stateful: False
    - require:
      - postgres_database: graphite_settings
      - file: graphite_settings
      - service: rsyslog
    - watch:
      - module: graphite-web
    - watch_in:
      - service: memcached

{#-
 load default user this way to prevent race condition between uWSGI process
#}
graphite_initial_fixture:
  file:
    - managed
    - name: /usr/local/graphite/salt-initial-fixture.xml
    - user: www-data
    - group: graphite
    - mode: 440
    - source: salt://graphite/initial-fixture.xml
    - require:
      - user: web
      - user: graphite
      - virtualenv: graphite
  module:
    - wait
    - name: django.command
    - command: loaddata /usr/local/graphite/salt-initial-fixture.xml
    - settings_module: graphite.settings
    - bin_env: /usr/local/graphite
    - stateful: False
    - require:
      - module: graphite_settings
      - file: graphite_initial_fixture
    - watch:
      - postgres_database: graphite_settings

graphite_admin_user:
  module:
    - wait
    - name: django.command
    - command: createsuperuser_plus --username={{ salt['pillar.get']('graphite:initial_admin_user:username') }} --email={{ salt['pillar.get']('graphite:initial_admin_user:email', 'root@example.com') }} --password={{ salt['pillar.get']('graphite:initial_admin_user:password') }}
    - settings_module: graphite.settings
    - bin_env: /usr/local/graphite
    - stateful: False
    - require:
      - module: graphite_settings
    - watch:
      - postgres_database: graphite_settings

/usr/local/graphite/bin/build-index.sh:
  file:
    - managed
    - template: jinja
    - source: salt://graphite/build-index.jinja2
    - user: root
    - group: root
    - mode: 555
    - require:
      - virtualenv: graphite
      - file: /var/lib/graphite/whisper
      - file: bash

graphite_patch_issue_608_pickle_unsafe:
  file:
    - patch
    - hash: md5=209cfbdefc2abdfff0fb4112270dcc16
    - name: /usr/local/graphite/lib/python2.7/site-packages/graphite/util.py
    - source: salt://graphite/pickle_608.patch
    - require:
      - virtualenv: graphite
    - watch_in:
      - module: graphite-web-uwsgi

/etc/nginx/conf.d/graphite.conf:
  file:
    - managed
    - template: jinja
    - source: salt://graphite/nginx.jinja2
    - user: root
    - group: www-data
    - mode: 440
    - context:
        appname: graphite
        root: /usr/local/graphite/webapp/
    - require:
      - file: graphite-web-uwsgi
      - pkg: nginx
    - watch_in:
      - service: nginx

extend:
  nginx:
    service:
      - watch:
        - user: graphite
{% if ssl %}
        - cmd: ssl_cert_and_key_for_{{ ssl }}
  nginx.conf:
    file:
      - context:
          ssl: {{ ssl }}
{% endif %}
