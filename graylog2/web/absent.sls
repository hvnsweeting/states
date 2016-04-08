{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "upstart/absent.sls" import upstart_absent with context -%}

/etc/nginx/conf.d/graylog2-web.conf:
  file:
    - absent
    - require_in:
      - service: graylog-web

{{ upstart_absent('graylog-web') }}

extend:
  graylog-web:
    user:
      - absent
      - require:
        - service: graylog-web
    group:
      - absent
      - require:
        - user: graylog-web
    pkg:
      - purged

{%- for file in ('/etc/graylog/web', '/etc/init.d/graylog-web') %}
{{ file }}:
  file:
    - absent
    - require:
      - service: graylog-web
{%- endfor %}
