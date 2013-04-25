{#
 pDNSd Nagios NRPE checks
 #}
include:
  - nrpe

/etc/nagios/nrpe.d/pdnsd.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://pdnsd/nrpe.jinja2
    - require:
      - pkg: nagios-nrpe-server

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/pdnsd.cfg
