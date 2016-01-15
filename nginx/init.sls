{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'upstart/rsyslog.jinja2' import manage_upstart_log with context -%}
include:
  - apt
  - hostname
  - rsyslog
  - ssl.dev
  - web

{% set bad_configs = ('default', 'example_ssl') %}

{% for filename in bad_configs %}
/etc/nginx/conf.d/{{ filename }}.conf:
  file:
    - absent
    - require:
      - pkg: nginx
{% endfor %}

/etc/nginx/mime.types:
  file:
    - absent
    - require:
      - pkg: nginx

nginx.conf:
  file:
    - managed
    - name: /etc/nginx/nginx.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://nginx/config.jinja2
    - require:
      - pkg: nginx
      - file: /etc/nginx/mime.types

nginx-old-init:
  file:
    - rename
    - name: /usr/share/nginx/init.d
    - source: /etc/init.d/nginx
    - require:
      - pkg: nginx
  cmd:
    - wait
    - name: dpkg-divert --divert /usr/share/nginx/init.d --add /etc/init.d/nginx
    - require:
      - module: nginx-old-init
    - watch:
      - file: nginx-old-init
  module:
    - wait
    - name: cmd.run
    - cmd: kill `cat /var/run/nginx.pid`
    - watch:
      - file: nginx-old-init

nginx-old-init-disable:
  cmd:
    - wait
    - name: update-rc.d -f nginx remove
    - require:
      - module: nginx-old-init
    - watch:
      - file: nginx-old-init

{% set logger_types = ('access', 'error') %}

{% for log_type in logger_types %}
/var/log/nginx/{{ log_type }}.log:
  file:
    - absent
    - require:
      - service: nginx

nginx-logger-{{ log_type }}:
  file:
    - absent
    - name: /etc/init/nginx-logger-{{ log_type }}.conf
    - require:
      - service: nginx-logger-{{ log_type }}
  service:
    - dead
{% endfor %}

/etc/logrotate.d/nginx:
  file:
    - absent
    - require:
      - pkg: nginx

nginx_dependencies:
  pkg:
    - installed
    - pkgs:
      - libpcre3-dev
      - zlib1g-dev
      - lsb-base
      - adduser
    - require:
      - pkg: ssl-dev
      - cmd: apt_sources

{%- set version = '1.7.9' %}
{%- set sub_version = '{0}-1~{1}'.format(version, grains['oscodename']) %}
{%- set filename = 'nginx_{0}_{1}.deb'.format(sub_version, grains['osarch']) %}

{#- PID file owned by root, no need to manage #}
nginx:
  file:
    - managed
    - name: /etc/init/nginx.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://nginx/upstart.jinja2
    - require:
      - pkg: nginx
      - file: nginx-old-init
      - module: nginx-old-init
  service:
    - running
    - enable: True
    - order: 50
    - watch:
      - host: hostname
      - user: web
      - file: nginx
      - file: nginx.conf
      - file: /etc/nginx/mime.types
{%- for filename in bad_configs %}
      - file: /etc/nginx/conf.d/{{ filename }}.conf
{%- endfor %}
      - pkg: nginx
      - user: nginx
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
  pkg:
    - installed
    - sources:
{%- if files_archive %}
      - nginx: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/{{ filename }}
{%- else %}
      {#- source: http://nginx.org/packages/mainline/ubuntu #}
      - nginx: https://archive.robotinfra.com/mirror/{{ filename }}
{%- endif %}
    - require:
      - host: hostname
      - user: web
      - pkg: nginx_dependencies
{%- for log_type in logger_types %}
      - file: nginx-logger-{{ log_type }}
{%- endfor %}
  user:
    - present
    - shell: /bin/false
    - require:
      - pkg: nginx

{{ manage_upstart_log('nginx') }}

{%- if salt['pkg.version']('nginx') not in ('', sub_version) %}
nginx_old_version:
  pkg:
    - removed
    - name: nginx
    - require_in:
      - pkg: nginx
{%- endif %}

/etc/apt/sources.list.d/nginx.org-packages_ubuntu-precise.list:
  file:
    - absent

{#- This robots.txt file is used to deny all search engine, only affect if
    specific app uses it.  #}
/var/www/robots.txt:
  file:
    - managed
    - user: root
    - group: root
    - mode: 644
    - contents: |
        User-agent: *
        Disallow: /
    - require:
      - pkg: nginx
      - user: web
      - file: /var/www
    - require_in:
      - service: nginx

nginx_verify_version:
  cmd:
    - wait
    - name: nginx -v 2>&1 | grep -q '{{ version }}'
    - watch:
      - service: nginx
