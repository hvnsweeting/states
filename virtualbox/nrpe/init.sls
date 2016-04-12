{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'nrpe/passive.jinja2' import passive_check with context %}

include:
  - apt.nrpe
  - nrpe

check_vbox_kernel_modules.py:
  file:
    - managed
    - name: /usr/lib/nagios/plugins/check_vbox_kernel_modules.py
    - source: salt://virtualbox/nrpe/check_vbox_kernel_modules.py
    - user: root
    - group: nagios
    - mode: 555
    - require:
      - pkg: nagios-nrpe-server
      - module: nrpe-virtualenv
      - file: nsca-virtualbox
    - require_in:
      - service: nagios-nrpe-server
      - service: nsca_passive

{{ passive_check('virtualbox') }}
