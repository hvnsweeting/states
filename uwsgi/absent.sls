{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "upstart/absent.sls" import upstart_absent with context -%}
{{ upstart_absent('uwsgi') }}

/usr/local/bin/uwsgi:
  file:
    - absent

{%- for file in ('/etc/uwsgi', '/etc/uwsgi.yml', '/var/lib/uwsgi') %}
{{ file }}:
  file:
    - absent
    - require:
      - service: uwsgi
{%- endfor %}
