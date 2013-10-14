{#-
Copyright (c) 2013, Lam Dang Tung

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Author: Lam Dang Tung <lamdt@familug.org>
Maintainer: Lam Dang Tung <lamdt@familug.org>

A blogging tool and content management system.
-#}
include:
  - nginx
  - local
  - {{ salt['pillar.get']('wordpress:mysql_variant', 'mariadb') }}.server
  - php.dev
  - uwsgi.php
{%- if salt['pillar.get']('wordpress:ssl', False) %}
  - ssl
{%- endif %}
  - web

{%- set version = "3.5.2" %}
{%- set wordpressdir = "/usr/local/wordpress" %}
{%- set dbuser = salt['pillar.get']('wordpress:db:username', 'wordpress') %}
{%- set dbuserpass = salt['password.pillar']('wordpress:db:password', 10) %}
{%- set dbname = salt['pillar.get']('wordpress:db:name', 'wordpress') %}

wordpress_drop_old_db:
  mysql_database:
    - absent
    - name: {{ dbname }}
    - require:
      - service: mysql-server
      - pkg: python-mysqldb

wordpress:
  archive:
    - extracted
    - name: /usr/local/
{%- if 'files_archive' in pillar %}
    - source: {{ pillar['files_archive'] }}/mirror/wordpress-{{ version }}.tar.gz
{%- else %}
    - source: http://wordpress.org/wordpress-{{ version }}.tar.gz
{%- endif %}
    - source_hash: md5=90acae65199db7b33084ef36860d7f22
    - archive_format: tar
    - tar_options: z
    - if_missing: {{ wordpressdir }}
    - require:
      - file: /usr/local
  file:
    - directory
    - name: {{ wordpressdir }}
    - user: www-data
    - group: www-data
    - recurse:
      - user
      - group
    - require:
      - archive: wordpress
  mysql_database:
    - present
    - name: {{ dbname }}
    - pkg: python-mysqldb
    - require:
      - service: mysql-server
      - pkg: python-mysqldb
      - mysql_database: wordpress_drop_old_db
  mysql_user:
    - present
    - host: localhost
    - name: {{ dbuser }}
    - password: {{ dbuserpass }}
    - require:
      - service: mysql-server
      - pkg: python-mysqldb
  mysql_grants:
    - present
    - grant: all privileges
    - user: {{ dbuser }}
    - database: {{ dbname }}.*
    - host: localhost
    - require:
      - mysql_user: wordpress
      - mysql_database: wordpress

php5-mysql:
  pkg:
    - installed
    - require:
      - pkg: php-dev

{{ wordpressdir }}/wp-config.php:
  file:
    - managed
    - name: {{ wordpressdir }}/wp-config.php
    - template: jinja
    - source: salt://wordpress/config.jinja2
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - archive: wordpress
      - user: web
    - context:
      dbuserpass: {{ dbuserpass }}
      dbname: {{ dbname }}
      dbuser: {{ dbuser }}

wordpress_initial:
  file:
    - managed
    - name: {{ wordpressdir }}/wp-admin/init.php
    - source: salt://wordpress/init.jinja2
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 440
    - require:
      - archive: wordpress
      - user: web
  cmd:
    - run
    - name: php init.php
    - cwd: {{ wordpressdir }}/wp-admin
    - user: www-data
    - require:
      - pkg: php-dev
      - pkg: php5-mysql
      - user: web
      - mysql_grants: wordpress
    - watch:
      - file: wordpress_initial
      - file: wordpress
      - file: {{ wordpressdir }}/wp-config.php
  module:
    - wait
    - grant: all privileges
    - user: wordpress
    - name: mysql.grant_add
    - database: wordpress.*
    - host: localhost
    - watch:
      - cmd: wordpress_initial

/etc/nginx/conf.d/wordpress.conf:
  file:
    - managed
    - source: salt://wordpress/nginx.jinja2
    - user: www-data
    - group: www-data
    - mode: 440
    - template: jinja
    - require:
      - pkg: nginx
      - uwsgi: uwsgi_wordpress
    - watch_in:
      - service: nginx
    - context:
      dir: {{ wordpressdir }}

uwsgi_wordpress:
  uwsgi:
    - available
    - enabled: True
    - name: wordpress
    - source: salt://wordpress/uwsgi.jinja2
    - user: www-data
    - group: www-data
    - mode: 440
    - template: jinja
    - context:
      dir: {{ wordpressdir }}
    - require:
      - module: wordpress_initial
      - service: uwsgi_emperor
      - service: mysql-server
    - watch:
      - file: {{ wordpressdir }}/wp-config.php
      - archive: wordpress
      - pkg: php5-mysql

{%- if salt['pillar.get']('wordpress:ssl', False) %}
extend:
  nginx:
    service:
      - watch:
       - cmd: /etc/ssl/{{ pillar['wordpress']['ssl'] }}/chained_ca.crt
        - module: /etc/ssl/{{ pillar['wordpress']['ssl'] }}/server.pem
        - file: /etc/ssl/{{ pillar['wordpress']['ssl'] }}/ca.crt
{%- endif %}
