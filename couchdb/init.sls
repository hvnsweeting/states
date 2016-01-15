{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'upstart/rsyslog.jinja2' import manage_upstart_log with context -%}
include:
  - apt
  - erlang
  - locale
  - rsyslog

{# mirror commands:
    wget -m -I couchdb/stable/ubuntu http://ppa.launchpad.net/couchdb/stable/ubuntu
    mv ppa.launchpad.net/couchdb/stable/ubuntu/dists ppa.launchpad.net/couchdb/stable/ubuntu/pool .
    rm -rf ppa.launchpad.net/
#}

couchdb:
  pkgrepo:
    - managed
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/couchdb {{ grains['oscodename'] }} main
    - key_url: salt://couchdb/key.gpg
{%- else %}
    - ppa: couchdb/stable
{%- endif %}
    - file: /etc/apt/sources.list.d/couchdb-stable.list
    - clean_file: True
    - require:
      - cmd: apt_sources
  pkg:
    - installed
    - name: couchdb
    - require:
      - pkg: erlang
      - pkgrepo: couchdb
  service:
    - running
    - require:
      - pkg: couchdb
    - watch:
      - file: couchdb
  file:
    - managed
    - name: /etc/couchdb/local.ini
    - source: salt://couchdb/config.jinja2
    - template: jinja
    - require:
      - pkg: couchdb

couchdb_redirect_log_to_syslog:
  file:
    - managed
    - name: /etc/rsyslog.d/couchdb.conf
    - mode: 440
    - source: salt://rsyslog/template.jinja2
    - template: jinja
    - require:
      - pkg: rsyslog
      - file: couchdb
      - service: couchdb
    - watch_in:
      - service: rsyslog
    - context:
        file_path: /var/log/couchdb/couch.log
        tag_name: couchdb
        severity: error
        facility: daemon

couchdb_logrotate_ensuring:
  file:
    - exists
    - name: /etc/logrotate.d/couchdb
    - require:
      - pkg: couchdb

{{ manage_upstart_log('couchdb') }}
