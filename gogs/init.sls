{#- Usage of this is governed by a license that can be found in doc/license.rst #}
{%- set ssl = salt['pillar.get']('gogs:ssl', False) -%}
{%- set version = '0.8.10' -%}
{%- set filename = "gogs_v" + version + "_linux_" + grains['osarch'] + ".tar.gz" -%}
{%- set cksum = {
    'i386': '51c27300b3f25fa476afcc67d1d49f86aeeefea5',
    'amd64': '7177a92da93053afc08731cf2ba80aca075b78fe'
} -%}
{%- from 'upstart/rsyslog.jinja2' import manage_upstart_log with context -%}
{%- set ssh_port = salt['pillar.get']('gogs:ssh', 2022) -%}
{%- set db_password = salt['password.pillar']('gogs:db_password', 10) -%}
include:
  - apt
  - git
  - nginx
  - git.server.user
  - postgresql.server
  - ssh.client
{%- if ssl %}
  - ssl
{%- endif %}

gogs:
  archive:
    - extracted
    - name: /usr/local/gogs/{{ version }}
    - source: https://archive.robotinfra.com/mirror/gogs/{{ filename }}
    - source_hash: sha1={{ cksum[grains['osarch']] }}
    - archive_format: tar
    - tar_options: z
    - if_missing: /usr/local/gogs/{{ version }}/gogs
    - require:
      - file: /usr/local/gogs/{{ version }}
{%- if ssh_port < 1024 %}
  pkg:
    - installed
    - name: libcap2-bin
    - require:
      - cmd: apt_sources
  cmd:
    - run
    - name: setcap 'cap_net_bind_service=+ep' /usr/local/gogs/{{ version }}/gogs/gogs
    - unless: 'getcap /usr/local/gogs/{{ version }}/gogs/gogs | grep cap_net_bind_service+ep'
    - require:
      - pkg: gogs
      - archive: gogs
    - watch_in:
      - service: gogs
{%- endif %}
  postgres_user:
    - present
    - name: gogs
    - password: {{ db_password }}
    - runas: postgres
    - require:
      - service: postgresql
  postgres_database:
    - present
    - name: gogs
    - owner: gogs
    - runas: postgres
    - require:
      - postgres_user: gogs
      - service: postgresql
  file:
    - managed
    - name: /etc/init/gogs.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://gogs/upstart.jinja2
    - context:
        version: {{ version }}
    - require:
      - file: /etc/gogs.ini
      - file: gogs-ssh-key
      - cmd: gogs-ssh-key
      - cmd: gogs-fix-permission
      - archive: gogs
      - file: /usr/local/gogs/{{ version }}
      - user: git-server
      - file: /usr/local/gogs
      - file: /usr/local/gogs/{{ version }}/gogs/data/avatars
  service:
    - running
    - enable: True
    - order: 50
    - watch:
      - archive: gogs
      - postgres_user: gogs
      - postgres_database: gogs
      - file: gogs
      - cmd: gogs-fix-permission
      - cmd: gogs-ssh-key
      - file: gogs-ssh-key
      - file: /usr/local/gogs/{{ version }}/gogs/data
      - file: /usr/local/gogs/{{ version }}/gogs/data/ssh
      - file: /usr/local/gogs/{{ version }}/gogs/data/avatars
      - file: /var/lib/gogs/ssh
      - file: /etc/gogs.ini
      - file: /usr/local/gogs
      - file: /usr/local/gogs/{{ version }}
      - user: git-server

gogs-fix-permission:
  cmd:
    - wait
    - name: chown -R root.root /usr/local/gogs/{{ version }}/*
    - watch:
      - archive: gogs

gogs-ssh-key:
  cmd:
    - run
    - name: ssh-keygen -t rsa -N '' -f /var/lib/gogs/ssh
    - unless: test -f /var/lib/gogs/ssh
    - require:
      - file: /var/lib/gogs
      - pkg: openssh-client
  file:
    - managed
    - user: root
    - group: git
    - mode: 440
    - name: /var/lib/gogs/ssh
    - replace: False
    - require:
      - cmd: gogs-ssh-key

/usr/local/gogs/{{ version }}/gogs/data:
  file:
    - directory
    - user: root
    - group: git
    - mode: 550
    - require:
      - archive: gogs

/usr/local/gogs/{{ version }}/gogs/data/tmp:
  file:
    - symlink
    - target: /tmp
    - user: git
    - group: git
    - mode: 550
    - require:
      - file: /usr/local/gogs/{{ version }}/gogs/data

/usr/local/gogs/{{ version }}/gogs/data/ssh:
  file:
    - directory
    - user: root
    - group: git
    - mode: 550
    - require:
      - file: /usr/local/gogs/{{ version }}/gogs/data

/usr/local/gogs/{{ version }}/gogs/data/avatars:
  file:
    - symlink
    - target: /var/lib/gogs/avatars
    - user: git
    - group: git
    - mode: 440
    - require:
      - file: /var/lib/gogs/avatars
      - file: /usr/local/gogs/{{ version }}/gogs/data

/usr/local/gogs/{{ version }}/gogs/data/ssh/gogs.rsa:
  file:
    - symlink
    - target: /var/lib/gogs/ssh
    - user: git
    - group: git
    - mode: 440
    - require:
      - file: /usr/local/gogs/{{ version }}/gogs/data/ssh
      - file: gogs-ssh-key

/etc/gogs.ini:
  file:
    - managed
    - source: salt://gogs/config.jinja2
    - user: root
    - group: git
    - template: jinja
    - mode: 440
    - require:
      - user: git-server
    - context:
        ssl: {{ ssl }}
        ssh_port: {{ ssh_port }}
        db_password: {{ db_password }}
    - show_diff: False

/usr/local/gogs:
  file:
    - directory
    - mode: 550
    - user: root
    - group: git
    - require:
      - user: git-server
{%- for dirname in ('log', 'lib') %}
/var/{{ dirname }}/gogs:
  file:
    - directory
    - user: git
    - group: git
    - mode: 770
    - require:
      - user: git-server
    - watch_in:
      - service: gogs
{%- endfor %}

/usr/local/gogs/{{ version }}:
  file:
    - directory
    - mode: 750
    - user: root
    - group: git
    - require:
      - file: /usr/local/gogs

{%- for dirname in ('sessions', 'repositories', 'avatars') %}
/var/lib/gogs/{{ dirname }}:
  file:
    - directory
    - user: git
    - group: git
    - mode: 770
    - require:
      - file: /var/lib/gogs
    - watch_in:
      - service: gogs
{%- endfor %}

{#- `file.find` module version 2014.7.5 does not support maxdepth #}
gogs_cleanup_old_versions:
  cmd:
    - wait
    - name: find /usr/local/gogs/ -maxdepth 1 -mindepth 1 -type d ! -name {{ version }} -print0 | xargs -0 rm -fr
    - watch:
      - archive: gogs

/etc/nginx/conf.d/gogs.conf:
  file:
    - managed
    - source: salt://gogs/nginx.jinja2
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - context:
        appname: gogs
        root: /usr/local/gogs/{{ version }}/gogs
        version: {{ version }}
    - require:
      - pkg: nginx
      - user: web
      - service: gogs
{%- if ssl %}
      - cmd: ssl_cert_and_key_for_{{ ssl }}
{%- endif %}
    - watch_in:
      - service: nginx

{{ manage_upstart_log('gogs') }}

{%- if ssl %}
extend:
  nginx.conf:
    file:
      - context:
          ssl: {{ ssl }}
  nginx:
    service:
      - watch:
        - cmd: ssl_cert_and_key_for_{{ ssl }}
{%- endif %}
