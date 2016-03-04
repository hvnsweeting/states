{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - rsyslog

/etc/python:
  file:
    - directory
    - user: root
    - group: root
    - mode: 755

python:
  pkg:
    - latest
    - name: python{{ grains['pythonversion'][0] }}.{{ grains['pythonversion'][1] }}
    - require:
      - cmd: apt_sources
  file:
    - managed
    - name: /etc/python/config.yml
    - source: salt://python/config.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 444
    - require:
      - file: /etc/python
      {#- This config contains `syslog` as a handler
      So, rsyslog service must be running before the consumer (`pysc`, ...) can use it #}
      - service: rsyslog
