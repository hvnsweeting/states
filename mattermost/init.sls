{%- set ssl = salt['pillar.get']('mattermost:ssl', False) %}
include:
  - local
  - nginx
  - postgresql.server
{% if ssl %}
  - ssl
{% endif %}

/usr/local/mattermost:
  file:
    - directory
    - user: root
    - group: mattermost
    - mode: 550
    - require:
      - user: mattermost
      - archive: mattermost
      - file: /usr/local

mattermost:
  user:
    - present
    - name: mattermost
    - gid_from_name: True
    - system: True
    - fullname: mattermost
    - shell: /usr/sbin/nologin
    - home: /var/lib/mattermost
    - createhome: True
    - password: "*"
    - enforce_password: True
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- set version = '3.0.2' %}
  archive:
    - extracted
    - name: /usr/local
{%- if files_archive %}
    - source: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/mattermost-{{ version }}.tar.gz
{%- else %}
    - source: https://github.com/mattermost/platform/releases/download/v{{ version }}/mattermost.tar.gz
{%- endif %}
    - source_hash: md5=751f237d227db6c8da73a79e41a545b2
    - archive_format: tar
    - tar_options: z
    - if_missing: /usr/local/mattermost/salt_mattermost_{{ version }}
    - require:
      - user: mattermost
      - file: /usr/local
  postgres_user:
    - present
    - name: mattermost
    - password: {{ salt['password.pillar']('mattermost:db:password', 10) }}
    - runas: postgres
    - require:
      - service: postgresql
  postgres_database:
    - present
    - name: mattermost
    - owner: mattermost
    - runas: postgres
    - require:
      - postgres_user: mattermost
      - service: postgresql
  file:
    - managed
    - name: /etc/init/mattermost.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 400
    - source: salt://mattermost/upstart.jinja2
    - require:
      - user: mattermost
  service:
    - running
    - name: mattermost
    - enable: True
    - require:
      - file: /usr/local/mattermost/en.json
    - watch:
      - file: mattermost
      - file: /etc/mattermost.json
      - file: /var/log/mattermost
      - archive: mattermost
    - require_in:
      - service: nginx

{#- https://forum.mattermost.org/t/cli-tool-crashing-missing-translation/959/5 #}
/usr/local/mattermost/en.json:
  file:
    - symlink
    - target: /usr/local/mattermost/i18n/en.json
    - require:
      - archive: mattermost

mattermost_version_manage:
  file:
    - managed
    - replace: False
    - name: /usr/local/mattermost/salt_mattermost_{{ version }}
    - require:
      - archive: mattermost
  cmd:
    - run
    - name: find /usr/local/mattermost/ -maxdepth 1 -mindepth 1 -type f -name 'salt_mattermost_*' ! -name 'salt_mattermost_{{ version }}' -delete
    - require:
      - archive: mattermost

/etc/mattermost.json:
  file:
    - managed
    - template: jinja
    - user: root
    - group: mattermost
    - mode: 440
    - source: salt://mattermost/config.jinja2
    - require:
      - user: mattermost

/var/log/mattermost:
  file:
    - directory
    - user: root
    - group: mattermost
    - mode: 770

/etc/nginx/conf.d/mattermost.conf:
  file:
    - managed
    - template: jinja
    - source: salt://mattermost/nginx.jinja2
    - user: root
    - group: www-data
    - mode: 440
    - context:
        appname: mattermost
        root: /usr/local/mattermost/web/
    - require:
      - pkg: nginx
      - service: mattermost
    - watch_in:
      - service: nginx

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
