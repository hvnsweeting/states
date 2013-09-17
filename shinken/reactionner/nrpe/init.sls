{#-
 Author: Bruno Clermont patate@fastmail.cn
 Maintainer: Bruno Clermont patate@fastmail.cn
 -#}
include:
  - nrpe
  - virtualenv.nrpe
  - pip.nrpe
  - python.dev.nrpe
  - apt.nrpe
{% if pillar['shinken']['ssl']|default(False) %}
  - ssl.nrpe
{% endif %}

/etc/nagios/nrpe.d/shinken-reactionner.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://shinken/reactionner/nrpe/config.jinja2
    - require:
      - pkg: nagios-nrpe-server

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/shinken-reactionner.cfg
