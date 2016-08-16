include:
  - apt
  - pip

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- set graphite_address = salt['pillar.get']('graphite_address', False) %}
{%- set version = "1.0.0-beta3" %}
{%- set mirror = files_archive|replace('file://', '')|replace('https://', 'http://') ~ "/mirror"
  if files_archive else "http://influxdb.s3.amazonaws.com"
%}
{%- set pkg_url = mirror ~ "/influxdb_" ~ version ~ "_" ~ grains["osarch"] ~ ".deb"%}
{%- set admin = salt["pillar.get"]("influxdb:admin", False) %}

influxdb:
  pkg:
    - installed
    - sources:
      - influxdb: {{ pkg_url }}
    - require:
      - cmd: apt_sources
  file:
    - managed
    - name: /etc/influxdb/influxdb.conf
    - template: jinja
    - source: salt://influxdb/config.jinja2
    - user: root
    - group: root
    - mode: 444
    - context:
        auth_enabled: "{{ "true" if admin else "false" }}"
    - require:
      - pkg: influxdb
  service:
    - running
    - require:
      - file: /var/run/influxdb
    - watch:
      - pkg: influxdb
      - file: influxdb
  process:
    - wait_socket
    - address: "127.0.0.1"
    - port: 8086
    - require:
      - service: influxdb

{%- for dir in ('lib', 'run') %}
/var/{{ dir }}/influxdb:
  file:
    - directory
    - user: influxdb
    - group: influxdb
    - mod: 755
    - require:
      - pkg: influxdb
{%- endfor %}

/var/opt/influxdb:
  file:
    - absent
    - require:
      - service: influxdb

{%- for dir in ('meta', 'data', 'hh') %}
/var/lib/influxdb/{{ dir }}:
  file:
    - directory
    - user: influxdb
    - group: influxdb
    - mod: 755
    - require:
      - file: /var/lib/influxdb
    - require_in:
      - file: influxdb
{%- endfor %}

python-influxdb:
  file:
    - managed
    - name: {{ opts["cachedir"] }}/pip/influxdb
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://influxdb/requirements.jinja2
    - require:
      - module: pip
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - requirements: {{ opts["cachedir"] }}/pip/influxdb
    - reload_modules: True
    - watch:
      - file: python-influxdb

influxdb_admin:
  cmd:
{%- if admin %}
    - run
    - name: |
        /usr/bin/influx -execute "CREATE USER {{ admin["user"] }} WITH PASSWORD '{{ admin["password"] }}' WITH ALL PRIVILEGES"
    - onlyif: |
        /usr/bin/influx -execute 'SHOW USERS' {# can query without authentication #}
{%- else %}
    - wait
    - name: echo 'influxdb authentication is disable'
{%- endif %}
    - require:
      - process: influxdb

{%- for db in salt["pillar.get"]("influxdb:databases", []) %}
influxdb_database_{{ db }}:
  cmd:
    - run
    - name: >
        /usr/bin/influx -execute "CREATE DATABASE {{ db }}"
  {%- if admin %}
        -username '{{ admin["user"] }}'
        -password '{{ admin["password"] }}'
  {%- endif %}
    - unless: >
        /usr/bin/influx -execute "SHOW DATABASES"
  {%- if admin %}
        -username '{{ admin["user"] }}'
        -password '{{ admin["password"] }}'
  {%- endif %}
        | sed -e '1,2d' | grep '^{{ db }}$'
    - require:
      - cmd: influxdb_admin
      - module: python-influxdb
{%- endfor %}
