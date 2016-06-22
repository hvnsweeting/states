{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'apparmor/macro.jinja2' import profile_managed with context %}

{%- set services = [] %}
{%- for server in salt['pillar.get']('openvpn:servers', {}) %}
  {%- do services.append('openvpn-' ~ server) %}
{%- endfor %}

{{ profile_managed('openvpn', '/usr/sbin/openvpn', services) }}
