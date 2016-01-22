include:
  - apt
  - rsyslog

/etc/python:
  file:
    - directory
    - user: root
    - group: root
    - mode: 755

python_config:
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
