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
  archive:
    - extracted
    - name: /usr/local
{%- if files_archive %}
    - source: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/mattermost-1.3.0.tar.gz
{%- else %}
    - source: https://github.com/mattermost/platform/releases/download/v1.3.0/mattermost.tar.gz
{%- endif %}
    - source_hash: md5=a423e138520ddfcd6f563f8515c34761
    - archive_format: tar
    - tar_options: z
    - if_missing: /usr/local/mattermost/bin/platform
    - require:
      - user: mattermost
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
      - archive: mattermost
    - watch:
      - file: mattermost
      - file: /etc/mattermost.json
      - file: /var/log/mattermost
    - require_in:
      - service: nginx

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
