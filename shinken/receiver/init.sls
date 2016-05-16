{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'shinken/init.sls' import shinken_install_module with context -%}
{% set ssl = salt['pillar.get']('shinken:ssl', False) %}
include:
  - rsyslog
  - shinken
{% if ssl %}
  - ssl
{% endif %}

{%- if salt['pillar.get']('files_archive', False) %}
    {%- call shinken_install_module('nsca') %}
- source_hash: md5=7dd8c372864bce48eb204a1444ad2ebd
    {%- endcall %}
{%- else %}
    {{ shinken_install_module('nsca') }}
{%- endif %}

shinken-receiver:
  file:
    - managed
    - name: /etc/init/shinken-receiver.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://shinken/upstart.jinja2
    - context:
        shinken_component: receiver
  service:
    - running
    - order: 50
    - enable: True
    - require:
      - file: /var/lib/shinken
      - file: /var/run/shinken
    - watch:
      - cmd: shinken
      - cmd: shinken-module-nsca
      - file: /etc/shinken/receiver.conf
      - file: shinken-receiver
      - user: shinken
{% if ssl %}
      - cmd: ssl_cert_and_key_for_{{ ssl }}
{% endif %}
{#- does not use PID, no need to manage #}
{% from 'upstart/rsyslog.jinja2' import manage_upstart_log with context %}
{{ manage_upstart_log('shinken-receiver', severity="info") }}

/etc/shinken/receiver.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: shinken
    - mode: 440
    - source: salt://shinken/config.jinja2
    - context:
        shinken_component: receiver
    - require:
      - virtualenv: shinken
      - user: shinken
      - file: /etc/shinken

shinken_receiver_restart_cron:
  file:
    - managed
    - name: /etc/cron.twice_daily/shinken_receiver_restart
    - source: salt://shinken/receiver/cron.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 500
    - require:
      - file: bash
      - file: /etc/cron.twice_daily
      - service: shinken-receiver
