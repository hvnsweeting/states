{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set servers = salt['pillar.get']('openvpn:servers', {}) %}

include:
  - diamond
{%- if servers %}
  - openvpn.server
{%- endif %}
  - rsyslog.diamond

{%- if servers %}
openvpn_diamond_collector:
  file:
    - managed
    - name: /etc/diamond/collectors/OpenVPNCollector.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://openvpn/server/diamond/config.jinja2
    - context:
        instances:
    {%- for instance in servers %}
          {{ instance }}: file:///var/log/openvpn/{{ instance }}.log
    {%- endfor %}
    - require:
      - file: /etc/diamond/collectors
    {%- for instance in servers %}
      - service: openvpn-{{ instance }}
    {%- endfor %}
    - watch_in:
      - service: diamond

openvpn_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require:
    {%- for instance in servers %}
      - service: openvpn-{{ instance }}
    {%- endfor %}
    - text:
      - |
        [[openvpn]]
        exe = ^\/usr\/sbin\/openvpn$
{%- endif %}
