{#-
 Author: Bruno Clermont patate@fastmail.cn
 Maintainer: Bruno Clermont patate@fastmail.cn
 
 Configure host name
 -#}
hostname:
  file:
    - managed
    - template: jinja
    - name: /etc/hostname
    - user: root
    - group: root
    - mode: 444
    - source: salt://hostname/hostname.jinja2
  host:
    - present
    - name: {{ grains['id'] }}
    - ip: 127.0.0.1
    - require:
      - cmd: hostname
  cmd:
    - wait
    - stateful: False
    - name: hostname `cat /etc/hostname`
    - watch:
      - file: hostname
