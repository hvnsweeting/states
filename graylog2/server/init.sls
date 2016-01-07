{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'macros.jinja2' import manage_pid with context -%}
{%- from 'upstart/rsyslog.jinja2' import manage_upstart_log with context -%}
{%- from "upstart/absent.sls" import upstart_absent with context %}
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
include:
  - python
  - apt
  - mongodb
  - mongodb.pymongo
  - java.7
  - graylog2
  - local
  - rsyslog
  - pysc
  - requests
{#-
  graylog2.server require elasticsearch, install it when testing to
  make the inputs importing work.  In production environment,
  elasticsearch doesn't need to be install in same machine as
  graylog2.server
#}
{%- set __test__ = salt['pillar.get']("__test__", False) %}
{%- if __test__ %}
  - elasticsearch
{%- endif %}

{%- set user = 'graylog' %}
{%- set mongodb_suffix = '0-20' %}
{%- set elasticsearch_suffix = '0-20' %}

/etc/graylog2:
  file:
    - absent

/var/lib/graylog2:
  file:
    - absent

/etc/graylog2.conf:
  file:
    - absent

/usr/local/graylog2-server-0.20.6:
  file:
    - absent

/var/log/graylog2:
  file:
    - absent

/var/run/graylog2:
  file:
    - absent

/etc/rsyslog.d/graylog2-server.conf:
  file:
    - absent

{{ upstart_absent('graylog2-server') }}
extend:
  graylog2-server:
    user:
      - absent
      - name: graylog2
      - require:
        - service: graylog2-server
    group:
      - absent
      - name: graylog2
      - require:
        - user: graylog2-server

{#- For cluster using, all node's data should be explicit: http,master,data,port and/or name #}
/etc/graylog/server/elasticsearch.yml:
  file:
    - managed
    - source: salt://elasticsearch/config.jinja2
    - template: jinja
    - user: root
    - group: {{ user }}
    - mode: 440
    - context:
        master: 'false'
        data: 'false'
        origin_state: graylog2.server
    - require:
      - pkg: graylog-server

/etc/graylog/server/server.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: {{ user }}
    - mode: 440
    - source: salt://graylog2/server/config.jinja2
    - context:
        mongodb_suffix: {{ mongodb_suffix }}
        elasticsearch_suffix: {{ elasticsearch_suffix }}
    - require:
      - pkg: graylog-server

/etc/default/graylog-server:
  file:
    - managed
    - template: jinja
    - user: root
    - group: {{ user }}
    - mode: 440
    - source: salt://graylog2/server/default.jinja2
    - require:
      - pkg: graylog-server

/etc/graylog/server/log4j.xml:
  file:
    - managed
    - template: jinja
    - user: root
    - group: {{ user }}
    - mode: 440
    - source: salt://graylog2/server/log4j.jinja2
    - require:
      - pkg: graylog-server
      - service: rsyslog

{#- write log directly to syslog #}
/var/log/graylog-server:
  file:
    - absent
    - require:
      - service: graylog-server

graylog-server:
  pkg:
    - latest
    - name: graylog-server
    - require:
      - pkgrepo: graylog
  file:
    - managed
    - name: /etc/init/graylog-server.conf
    - source: salt://graylog2/server/upstart.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: graylog-server
  service:
    - running
    - enable: True
    - order: 50
    - watch:
      - pkg: jre-7
      - file: jre-7
      - file: /etc/graylog/server/server.conf
      - file: /etc/graylog/server/elasticsearch.yml
      - file: /etc/default/graylog-server
      - file: /etc/graylog/server/log4j.xml
      - file: graylog-server
    - require:
      - service: mongodb
{%- if salt['pillar.get']("__test__", False) %}
      - process: elasticsearch
{%- endif %}
{%- set parsed_url = salt['common.urlparse'](salt['pillar.get']('graylog2:rest_listen_uri', 'http://127.0.0.1:12900')) -%}
{%- set hostname = parsed_url.hostname %}
{%- set port = parsed_url.port %}
  process:
    - wait_socket
    - address: {{ hostname }}
    - port: {{ port }}
    - require:
      - service: graylog-server

{{ manage_upstart_log('graylog-server') }}

import_graylog2_gelf:
  graylog:
    - gelf_input
    {#- The following parameters have their default values and are unnecessary #}
    - title: gelf
    - stype: udp
    - port: 12201
    - bind_address: 0.0.0.0
    - buffer_size: 1048576
    - require:
      - process: graylog-server
      - module: requests

import_graylog2_syslog:
  graylog:
    - syslog_input
    {#- The following parameters have their default values and are unnecessary #}
    - title: syslog
    - stype: udp
    - port: 1514
    - bind_address: 0.0.0.0
    - buffer_size: 1048576
    - allow_override_date: true
    - store_full_message: false
    - force_rdns: false
    - require:
      - process: graylog-server
      - module: requests

{%- set streams = salt['pillar.get']('graylog2:streams', {}) %}
{%- for stream_name, stream_data in streams.iteritems() %}
  {%- set rules = stream_data['rules']|default([]) %}
  {%- set receivers = stream_data['receivers']|default([]) %}
  {%- set alert_grace = stream_data['alert_grace']|default(1) %}
  {% set receivers_type = stream_data['receivers_type']|default("emails") %}
{{ stream_name|lower|replace(' ', '_') }}_graylog2_stream:
  graylog_stream:
    - present
    - name: {{ stream_name }}
  {%- if rules %}
    - rules:
      {%- for rule in rules %}
      - field: {{ rule['field'] }}
        value: {{ rule['value'] }}
        inverted: {{ rule['inverted'] }}
        type: {{ rule['type'] }}
      {%- endfor %}
  {%- endif %}
    - receivers:
  {%- for receiver in receivers %}
      - {{ receiver }}
  {%- endfor %}
    - receivers_type: {{ receivers_type }}
    - alert_grace: {{ alert_grace }}
    - require:
      - process: graylog-server
      - module: requests
{%- endfor %}

{%- set mirror = files_archive|replace('file://', '')|replace('https://', 'http://') if files_archive else "http://archive.robotinfra.com" %}
{%- set alarmcallback_jabber = mirror ~ "/mirror/alarmcallback-jabber-1.1.0-SNAPSHOT.deb" %}
graylog-alarmcallback-jabber:
  pkg:
    - installed
    - sources:
      - graylog-alarmcallback-jabber: {{ alarmcallback_jabber }}
    - require:
      - cmd: apt_sources
    - watch_in:
      - service: graylog-server

{%- set slack_plugin_version = "1.1.5" %}
{%- set slack_plugin_name = "graylog-plugin-slack-" ~
                            slack_plugin_version ~ ".jar" %}
{%- set slack_plugin_source = mirror ~ "/mirror/" ~
                              slack_plugin_name %}
{%- set slack_plugin_source_hash = "md5=6d7d90e52a436f89b90a2d697c3ed67f" %}

graylog-plugin-slack:
  file:
    - managed
    - name: /usr/share/graylog-server/plugin/{{ slack_plugin_name }}
    - source: {{ slack_plugin_source }}
    - source_hash: {{ slack_plugin_source_hash }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: graylog-server
    - watch_in:
      - service: graylog-server

{%- set sentry_dsn = salt['pillar.get']('sentry_dsn', False) %}
{%- if sentry_dsn %}
  {%- set raven_version = "6.0.0" %}
  {%- set raven_libs = {
    "raven": "md5=5351075504d9c04179b0ea4f7cec6487",
    "raven-log4j": "md5=6eb3101aa7a8d8b1ab845dea0f55f032"
  } %}

  {%- for lib, hash in raven_libs.iteritems() %}
    {%- set filename = lib ~ "-" ~ raven_version ~ ".jar" %}
graylog_{{ lib }}:
  file:
    - managed
    - name: /usr/share/graylog-server/lib/{{ filename }}
    - source: {{ mirror }}/mirror/{{ filename }}
    - source_hash: {{ hash }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: graylog-server
    - watch_in:
      - service: graylog-server
  {%- endfor %}
{%- endif %}
