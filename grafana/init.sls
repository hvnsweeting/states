{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set ssl = salt['pillar.get']('grafana:ssl', False) %}
{%- from 'upstart/rsyslog.jinja2' import manage_upstart_log with context -%}
include:
  - nginx
  - postgresql.server
  - rsyslog
{% if ssl %}
  - ssl
{% endif %}

grafana:
  pkg:
    - installed
    - sources:
      - grafana: https://grafanarel.s3.amazonaws.com/builds/grafana_3.1.1-1470047149_amd64.deb
{#
# {%- if files_archive %}
#     - source: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/grafana-{{ version }}.tar.gz
# {%- else %}
#{%- endif %}
#}
  postgres_user:
    - present
    - name: grafana
    - password: {{ salt['password.pillar']('grafana:db:password', 10) }}
    - runas: postgres
    - require:
      - service: postgresql
  postgres_database:
    - present
    - name: grafana
    - owner: grafana
    - runas: postgres
    - require:
      - postgres_user: grafana
      - service: postgresql
  file:
    - managed
    - name: /etc/grafana/grafana.ini
    - template: jinja
    - source: salt://grafana/config.jinja2
    - user: root
    - group: grafana
    - mode: 440
    - require:
      - pkg: grafana
      - postgres_database: grafana
  service:
    - running
    - name: grafana-server
    - enable: True
    - watch:
      - file: grafana

grafana_nginx_config:
  file:
    - managed
    - name: /etc/nginx/conf.d/grafana.conf
    - template: jinja
    - source: salt://grafana/nginx.jinja2
    - user: root
    - group: www-data
    - mode: 440
    - context:
        appname: grafana
        root: /usr/share/grafana/public/
    - require:
      - pkg: nginx
      - service: grafana
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
