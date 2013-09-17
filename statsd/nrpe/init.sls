{#-
 Author: Bruno Clermont patate@fastmail.cn
 Maintainer: Bruno Clermont patate@fastmail.cn
 
 Nagios NRPE check for StatsD
-#}
include:
  - nrpe
  - python.dev.nrpe
  - rsyslog.nrpe
  - virtualenv.nrpe

/etc/nagios/nrpe.d/statsd.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://statsd/nrpe/config.jinja2
    - require:
      - pkg: nagios-nrpe-server

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/statsd.cfg
