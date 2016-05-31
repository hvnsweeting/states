{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "upstart/absent.sls" import upstart_absent with context -%}

{%- set upstart_files = salt['file.find'](path='/etc/init/', regex='openvpn-(?!client).+\.conf', type='f', print='name') -%}
    {%- for filename in upstart_files -%}
        {%- set instance = filename.replace('openvpn-', '').replace('.conf', '') %}

{{ upstart_absent('openvpn-' + instance) }}

openvpn_absent_{{ instance }}:
  file:
    - absent
    - name: /etc/openvpn/{{ instance }}
    - require:
      - service: openvpn-{{ instance }}
    {%- endfor %}

/etc/default/openvpn:
  file:
    - absent

{%- for type in ('lib', 'run', 'log') %}
/var/{{ type }}/openvpn:
  file:
    - absent
{%- endfor %}

{%- for file in ('dh.pem', 'ca.crt', 'ca.key') %}
/etc/openvpn/{{ file }}:
  file:
    - absent
{%- endfor %}

openvpn_absent_serial:
  cmd:
    - run
    - name: rm -f {{ opts['cachedir'] }}/*.serial
