{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "upstart/absent.sls" import upstart_absent with context -%}
{{ upstart_absent('gogs') }}

{%- for filename in ('/etc/gogs', '/usr/local/gogs', '/var/lib/gogs', '/etc/gogs.ini') %}
{{ filename }}:
  file:
    - absent
    - require:
      - service: diamond
{%- endfor %}
