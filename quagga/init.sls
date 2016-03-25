{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "os.jinja2" import os with context %}

include:
  - apt

{%- set upgrade = salt['pillar.get']('quagga:upgrade', False) %}

quagga:
{%- if upgrade %}
  debconf:
    - set
    - data:
        'quagga/really_stop': {'type': 'boolean', 'value': 'true'}
    - require:
      - pkg: apt_sources
    - require_in:
      - pkg: quagga
{%- endif %}
  pkg:
    - installed
{%- if not upgrade %}
    {#- stderr: *** As requested via Debconf, the Quagga daemon will not stop! *** #}
    - hold: True
{%- endif %}
    - require:
      - cmd: apt_sources
  file:
    - managed
    - name: /etc/quagga/daemons
    - source: salt://quagga/config.jinja2
    - template: jinja
    - user: root
    - group: quagga
    - mode: 440
    - require:
      - pkg: quagga
  service:
    - running
    - watch:
      - file: quagga

{#- SysV init script in precise missing status) action #}
{%- if os.is_precise %}
/etc/init.d/quagga:
  file:
    - managed
    - source: salt://quagga/sysvinit.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 550
    - require:
      - pkg: quagga
    - watch_in:
      - service: quagga
{%- endif %}

{%- for file in ('zebra', 'ospfd', 'ospf6d', 'debian', 'vtysh') %}
/etc/quagga/{{ file }}.conf:
  file:
    - managed
    - source: salt://quagga/{{ file }}.jinja2
    - template: jinja
    - user: root
    - group: quagga
    - mode: 440
    - show_diff: False
    - require:
      - pkg: quagga
    - watch_in:
      - service: quagga
{%- endfor %}

/etc/environment:
  file:
    - append
    - text: |
        VTYSH_PAGER=more
