{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'apparmor/macro.jinja2' import gen_profile with context %}

{%- set services = [] %}
{%- for server in salt['pillar.get']('openvpn:servers', {}) %}
  {%- do services.append('openvpn-' ~ server) %}
{%- endfor %}

{{ gen_profile('openvpn', 'usr.sbin.openvpn', services) }}
