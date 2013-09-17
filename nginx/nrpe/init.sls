{#-
 Author: Bruno Clermont patate@fastmail.cn
 Maintainer: Bruno Clermont patate@fastmail.cn

 Nagios NRPE check for Nginx
-#}
include:
  - nrpe
  - apt.nrpe
  - rsyslog.nrpe

/etc/nagios/nrpe.d/nginx.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://nginx/nrpe/config.jinja2
    - require:
      - pkg: nagios-nrpe-server

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/nginx.cfg
