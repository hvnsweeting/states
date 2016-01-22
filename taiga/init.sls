{#- Usage of this is governed by a license that can be found in doc/license.rst -#}
{%- set ssl = salt['pillar.get']('taiga:ssl', False) %}

include:
  - apt
  - local
  - memcache
  - nginx
  - pip
  - postgresql.server
  - python.3.dev
  - rsyslog
{% if ssl %}
  - ssl
{% endif %}
  - uwsgi.python3
  - virtualenv
  - web
  - xml

taiga:
  virtualenv:
    - manage
    - name: /usr/local/taiga
    - system_site_packages: False
    - python: python3
    - require:
      - module: virtualenv
      - file: /usr/local
  archive:
    - extracted
    - name: /usr/local/taiga
    - source: https://github.com/taigaio/taiga-back/archive/1.9.1.tar.gz
    - source_hash: md5=38c5f33bc26bd2f1ffd1ea50f1fffb5c
    - if_missing: /usr/local/taiga/taiga-back-1.9.1/requirements.txt
    - archive_format: tar
    - tar_options: z
    - require:
      - virtualenv: taiga
  file:
    - symlink
    - name: /usr/local/taiga-back
    - target: /usr/local/taiga/taiga-back-1.9.1
    - force: True
    - require:
      - archive: taiga
  pkg:
    - latest
    - pkgs:
        - libevent-dev
        - libffi-dev
        - libfreetype6-dev
        - libzmq3-dev
        - libgdbm-dev
        - libncurses5-dev
        - gettext
        - libtool
        - binutils-doc
        - autoconf
        - flex
        - bison
        - libjpeg-dev
    - require:
      - cmd: apt_sources
      - pkg: build
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/taiga/bin/pip
    - requirements: /usr/local/taiga-back/requirements.txt
    - require:
      - virtualenv: taiga
      - pkg: xml-dev
      - file: taiga
    - watch:
      - pkg: taiga
      - pkg: python3-dev
      - pkg: postgresql-dev
      - archive: taiga
  cmd:
    - wait
    - name: find /usr/local/taiga-back -name '*.pyc' -delete
    - stateful: False
    - watch:
      - module: taiga
  postgres_user:
    - present
    - name: taiga
    - password: {{ salt['password.pillar']('taiga:db:password', 10) }}
    - runas: postgres
    - require:
      - service: postgresql
  postgres_database:
    - present
    - name: taiga
    - owner: taiga
    - runas: postgres
    - require:
      - postgres_user: taiga
      - service: postgresql

taiga_patch_580:
  file:
    - patch
    - source: salt://taiga/pr580.patch
    - name: /usr/local/taiga-back/taiga/base/storage.py
    - hash: md5=3ce4f5f9ef24d051ef79d9748f46e834
    - require:
      - archive: taiga
    - require_in:
      - module: taiga_uwsgi

taiga_additional_requirements:
  file:
    - managed
    - name: {{ opts['cachedir'] }}/pip/taiga
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://taiga/requirements.jinja2
    - require:
      - virtualenv: taiga
      - pkg: taiga
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/taiga/bin/pip
    - requirements: {{ opts['cachedir'] }}/pip/taiga
    - require:
      - pkg: taiga
    - watch:
      - file: taiga_additional_requirements
    - watch_in:
      - service: memcached

taiga_uwsgi:
  file:
    - managed
    - name: /etc/uwsgi/taiga.yml
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - source: salt://taiga/uwsgi.jinja2
    - context:
        appname: taiga
        module: taiga.wsgi
        virtualenv: /usr/local/taiga
        chdir: /usr/local/taiga-back/
        django_settings: settings.local
    - require:
      - service: uwsgi
      - service: rsyslog
      - file: taiga_settings
      - module: taiga_additional_requirements
      - module: taiga
      - file: taiga_patch_580
  module:
    - wait
    - name: file.touch
    - m_name: /etc/uwsgi/taiga.yml
    - require:
      - file: /etc/uwsgi/taiga.yml
    - watch:
      - file: taiga
      - file: /var/lib/deployments/taiga
      - file: /var/lib/deployments/taiga/media

taiga_settings:
  file:
    - managed
    - name: /usr/local/taiga-back/settings/local.py
    - source: salt://taiga/config.jinja2
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - require:
      - user: web
      - archive: taiga
      - file: taiga

taiga_front_dist:
  archive:
    - extracted
    - name: /usr/local/taiga
    - source: https://github.com/taigaio/taiga-front-dist/archive/1.9.1-stable.tar.gz
    - source_hash: md5=580fd125119d56374f9ace4c6a81466d
    - if_missing: /usr/local/taiga/taiga-front-dist-1.9.1-stable
    - archive_format: tar
    - tar_options: z
  file:
    - managed
    - name: /usr/local/taiga/taiga-front-dist-1.9.1-stable/dist/conf.json
    - source: salt://taiga/front_config.jinja2
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - require:
      - user: web
      - archive: taiga_front_dist

taiga_migrate:
  cmd:
    - wait
    - name: /usr/local/taiga/bin/django-admin migrate --noinput --settings=settings.local --pythonpath=/usr/local/taiga-back
    - user: www-data
    - cwd: /usr/local/taiga-back
    - require:
      - module: taiga
      - file: taiga_settings
      - service: rsyslog
    - watch:
      - postgres_database: taiga

taiga_admin_user:
  cmd:
    - wait
    - name: /usr/local/taiga/bin/django-admin loaddata initial_user --settings=settings.local --pythonpath=/usr/local/taiga-back
    - user: www-data
    - require:
      - file: taiga_settings
    - watch:
      - cmd: taiga_migrate
      - postgres_database: taiga

taiga_initial_project_templates:
  cmd:
    - wait
    - name: /usr/local/taiga/bin/django-admin loaddata initial_project_templates --settings=settings.local --pythonpath=/usr/local/taiga-back
    - user: www-data
    - require:
      - module: taiga
      - file: taiga_settings
      - service: rsyslog
    - watch:
      - cmd: taiga_admin_user
      - postgres_database: taiga

taiga_initial_role:
  cmd:
    - wait
    - name: /usr/local/taiga/bin/django-admin loaddata initial_role --settings=settings.local --pythonpath=/usr/local/taiga-back
    - require:
      - module: taiga
      - file: taiga_settings
      - service: rsyslog
    - watch:
      - cmd: taiga_initial_project_templates
      - postgres_database: taiga

taiga_compilemessages:
  cmd:
    - wait
    - name: /usr/local/taiga/bin/django-admin compilemessages --settings=settings.local --pythonpath=/usr/local/taiga-back
    - require:
      - module: taiga
      - file: taiga_settings
      - service: rsyslog
      - file: web
    - watch:
      - cmd: taiga_initial_role
      - postgres_database: taiga

taiga_collectstatic:
  cmd:
    - wait
    - name: /usr/local/taiga/bin/django-admin collectstatic --noinput --settings=settings.local --pythonpath=/usr/local/taiga-back
    - user: www-data
    - require:
      - file: web
      - module: taiga
      - file: taiga_settings
      - service: rsyslog
    - watch:
      - cmd: taiga_compilemessages
      - postgres_database: taiga
      - file: taiga_settings

/etc/nginx/conf.d/taiga.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - source: salt://taiga/nginx.jinja2
    - context:
        appname: taiga
        root: /var/lib/deployments/taiga
        statics:
          - static
    - require:
      - pkg: nginx
      - file: taiga_uwsgi
      - file: /var/lib/deployments/taiga
    - watch_in:
      - service: nginx

/var/lib/deployments/taiga:
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
      - file: taiga_uwsgi

/var/lib/deployments/taiga/media:
  file:
    - directory
    - user: www-data
    - group: www-data
    - makedirs: True
    - mode: 750
    - require:
      - file: web
      - file: /var/lib/deployments/taiga

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
