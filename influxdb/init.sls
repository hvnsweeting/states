include:
  - apt
  - pip

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- set graphite_address = salt['pillar.get']('graphite_address', False) %}
{%- set version = "0.9.1" %}
{%- set mirror = files_archive|replace('file://', '')|replace('https://', 'http://') ~ "/mirror"
  if files_archive else "http://influxdb.s3.amazonaws.com"
%}
{%- set pkg_url = mirror ~ "/influxdb_" ~ version ~ "_" ~ grains["osarch"] ~ ".deb"%}

influxdb:
  pkg:
    - installed
    - sources:
      - influxdb: {{ pkg_url }}
    - require:
      - cmd: apt_sources
  file:
    - managed
    - name: /etc/opt/influxdb/influxdb.conf
    - template: jinja
    - source: salt://influxdb/config.jinja2
    - user: root
    - group: root
    - mode: 444
    - require:
      - pkg: influxdb
  service:
    - running
    - watch:
      - pkg: influxdb
      - file: influxdb

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

{%- for db in salt["pillar.get"]("influxdb:databases", []) %}
influxdb_database_{{ db }}:
  influxdb_database:
    - present
    - name: {{ db }}
    - require:
      - service: influxdb
      - module: python-influxdb
{%- endfor %}
