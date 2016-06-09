{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - cron.nrpe
  - nrpe
  - virtualenv.nrpe

check_ssl_configuration.py:
  file:
    - managed
    - name: /usr/lib/nagios/plugins/check_ssl_configuration.py
    - source: salt://sslyze/nrpe/check_ssl_configuration.py
    - user: root
    - group: nagios
    - mode: 550
    - require:
      - host: hostname
      - pkg: nagios-nrpe-server
      - module: nrpe-virtualenv
{#- consumers of sslyze check use cron, make them only require sslyze check script #}
      - pkg: cron
    - require_in:
      - service: nagios-nrpe-server
      - service: nsca_passive
