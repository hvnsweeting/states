{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set __test__ = salt['pillar.get']('__test__', False) %}

include:
  - openvpn.server
{%- if not __test__ %}
  - salt.master
{%- endif %}

openvpn_pillar:
  file:
    - managed
    - name: {{ grains['saltpath'] }}/pillar/openvpn.py
    - source: salt://openvpn/server/pillar/ext_pillar.py
    - user: root
    - group: root
    - mode: 444
    - require:
      - sls: openvpn.server
{%- if not __test__ %}
    - watch_in:
      - service: salt-master

openvpn_ext_pillar_config:
  file:
  {%- if salt['pillar.get']('salt_master:ext_pillar:git', []) %}
    - accumulated
    - name: ext_pillar
    - filename: /etc/salt/master.d/ext_pillar.conf
    - text: |
        - openvpn: {}
    - require_in:
      - file: /etc/salt/master.d/ext_pillar.conf
  {%- else %}
    - managed
    - name: /etc/salt/master.d/ext_pillar.conf
    - source: salt://openvpn/server/pillar/config.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 440
  {%- endif %}
    - require:
      - file: openvpn_pillar
    - watch_in:
      - service: salt-master
{%- else %}
/etc/salt/minion.d/ext_pillar.conf:
  file:
    - managed
    - source: salt://openvpn/server/pillar/config.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 440
{%- endif %}
