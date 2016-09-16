{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - diamond
  - rsyslog.diamond

uwsgi_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[uwsgi]]
        cmdline = ^\/usr\/local\/bin\/uwsgi
{%- set test = salt['pillar.get']('__test__', False) %}
{%- if test or (grains['virtual'] == 'kvm' and salt['file.file_exists']('/sys/kernel/mm/ksm/run')) %}
diamond_ksm:
  file:
    - managed
    - name: /etc/diamond/collectors/KSMCollector.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://diamond/basic_collector.jinja2
    - require:
      - file: /etc/diamond/collectors
    - watch_in:
      - service: diamond
{%- endif -%}
