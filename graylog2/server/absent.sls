{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "upstart/absent.sls" import upstart_absent with context -%}

{{ upstart_absent("graylog-server")}}

extend:
  graylog-server:
    user:
      - absent
      - name: graylog
      - require:
        - service: graylog-server
    group:
      - absent
      - name: graylog
      - require:
        - user: graylog-server
    pkg:
      - purged

{%- for file in ('/etc/graylog/server', '/etc/init.d/graylog-server') %}
{{ file }}:
  file:
    - absent
    - require:
      - service: graylog-server
{%- endfor %}

{%- for dir in ('lib', 'plugin') %}
/usr/share/graylog-server/{{ dir }}:
  file:
    - absent
    - require_in:
      - pkg: graylog-server
{%- endfor %}
