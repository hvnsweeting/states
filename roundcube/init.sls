{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set ssl = salt['pillar.get']('roundcube:ssl', False) %}

include:
  - local
  - nginx
  - php.dev
  - postgresql.server
  - php_fpm
{%- if ssl %}
  - ssl
{%- endif %}
  - web

{%- set version = "1.0.1" %}
{%- set roundcubedir = "/usr/local/roundcubemail-" + version %}
{%- set dbname = salt['pillar.get']('roundcube:db:name', 'roundcube') %}
{%- set dbuser = salt['pillar.get']('roundcube:db:username', 'roundcube') %}
{%- set dbuserpass = salt['password.pillar']('roundcube:db:password', 10) %}

php5-pgsql:
  pkg:
    - installed
    - require:
      - pkg: php-dev

roundcube:
  user:
    - present
    - shell: /sbin/nologin
{#- temp dir for roundcube app, it needs to write temp data in this dir #}
    - home: /var/lib/roundcube
    - password: "*"
    - enforce_password: True
    - gid_from_name: True
    - groups:
      - www-data
    - require:
      - user: web
    - require_in:
      - service: php-fpm
  archive:
    - extracted
    - name: /usr/local/
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - source: {{ files_archive }}/mirror/roundcubemail-{{ version }}.tar.gz
{%- else %}
    - source: http://jaist.dl.sourceforge.net/project/roundcubemail/roundcubemail/{{ version }}/roundcubemail-{{ version }}.tar.gz
{%- endif %}
    - source_hash: md5=2e1629ea21615005b0a991e591f36363
    - archive_format: tar
    - tar_options: z
    - if_missing: {{ roundcubedir }}
    - require:
      - file: /usr/local
  postgres_user:
    - present
    - name: {{ dbuser }}
    - password: {{ dbuserpass }}
    - runas: postgres
    - require:
      - service: postgresql
  postgres_database:
    - present
    - name: {{ dbname }}
    - owner: {{ dbuser }}
    - runas: postgres
    - require:
      - postgres_user: roundcube

{{ roundcubedir }}:
  file:
    - directory
    - user: root
    - group: www-data
    - mode: 555
    - dir_mode: 555
    - file_mode: 440
    - recurse:
      - mode
      - user
      - group
    - require:
      - archive: roundcube
      - user: web

{{ roundcubedir }}/SQL:
  file:
    - directory
    - user: root
    - group: www-data
    - mode: 555
    - dir_mode: 555
    - file_mode: 444
    - recurse:
      - mode
      - user
      - group
    - require:
      - file: {{ roundcubedir }}
      - user: web

{{ roundcubedir }}/installer:
  file:
    - absent
    - require:
      - archive: roundcube

{{ roundcubedir }}/config/db.inc.php:
  file:
    - absent

{{ roundcubedir }}/config/main.inc.php:
  file:
    - absent

{{ roundcubedir }}/config/config.inc.php:
  file:
    - managed
    - source: salt://roundcube/config.jinja2
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - show_diff: False
    - context:
        password: {{ dbuserpass }}
        dbname: {{ dbname }}
        username: {{ dbuser }}
    - require:
      - file: {{ roundcubedir }}
      - user: web
      - file: {{ roundcubedir }}/config/main.inc.php
      - file: {{ roundcubedir }}/config/db.inc.php

roundcube_password_plugin_ldap_driver_dependency:
  pkg:
    - installed
    - pkgs:
      - php5-cgi {#- on Trusty, php-net-ldap2 require php5, which in turn require one of four php provider packages, php5-cgi is the lightest and not require apache2 #}
      - php-net-ldap2

{{ roundcubedir }}/plugins/password/config.inc.php:
  file:
    - managed
    - source: salt://roundcube/password_plugin.jinja2
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - require:
      - file: {{ roundcubedir }}
      - user: web
      - pkg: roundcube_password_plugin_ldap_driver_dependency

{{ roundcubedir }}/plugins/managesieve/config.inc.php:
  file:
    - managed
    - source: salt://roundcube/sieve_plugin.jinja2
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - require:
      - file: {{ roundcubedir }}
      - user: web

{#- this app logs directly to syslog, then there is no need for this dir #}
{{ roundcubedir }}/logs:
  file:
    - absent
    - require:
      - file: {{ roundcubedir }}

/etc/nginx/conf.d/roundcube.conf:
  file:
    - managed
    - source: salt://roundcube/nginx.jinja2
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - require:
      - pkg: nginx
      - user: web
      - service: php-fpm
    - context:
        appname: roundcube
        root: {{ roundcubedir }}
    - watch_in:
      - service: nginx

roundcube_initial:
  cmd:
    - wait
    - name: psql -f {{ roundcubedir }}/SQL/postgres.initial.sql -d roundcube
    - user: postgres
    - group: postgres
    - require:
      - service: postgresql
      - postgres_database: roundcube
    - watch:
      - archive: roundcube
  module:
    - wait
    - name: postgres.owner_to
    - dbname: roundcube
    - ownername: roundcube
    - runas: postgres
    - watch:
      - cmd: roundcube_initial
      - file: {{ roundcubedir }}/config/config.inc.php
      - file: {{ roundcubedir }}
      - pkg: php5-pgsql
      - pkg: roundcube_password_plugin_ldap_driver_dependency

{%- if ssl %}
extend:
  php-fpm:
    service:
      - watch:
        - module: roundcube_initial
  nginx.conf:
    file:
      - context:
          ssl: {{ ssl }}
  nginx:
    service:
      - watch:
        - cmd: ssl_cert_and_key_for_{{ ssl }}
{% endif %}
