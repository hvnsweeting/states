{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - hostname
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

{#- PID file owned by root, no need to manage #}
nginx:
  service:
    - running
    - enable: True
    - order: 50
    - watch:
      - host: hostname
      - user: web
      - file: nginx.conf
      - file: /etc/nginx/mime.types
{%- for filename in bad_configs %}
      - file: /etc/nginx/conf.d/{{ filename }}.conf
{%- endfor %}
      - pkg: nginx
      - user: nginx
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
  pkgrepo:
    - managed
    - key_url: http://nginx.org/keys/nginx_signing.key
    - name: deb http://nginx.org/packages/mainline/ubuntu/ {{ grains['oscodename'] }} nginx
    - require:
      - pkg: apt_sources
  pkg:
    - latest
    - require:
      - host: hostname
      - user: web
      - pkg: nginx_dependencies
      - pkgrepo: nginx
  user:
    - present
    - shell: /bin/false
    - require:
      - pkg: nginx
  file:
    - managed
    - name: /lib/systemd/system/nginx.service
    - source: salt://nginx/systemd.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx
      - user: web
      - file: /var/www
    - require_in:
      - service: nginx

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
