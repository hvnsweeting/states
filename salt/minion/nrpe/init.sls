{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'nrpe/passive.jinja2' import passive_check with context %}
include:
  - apt.nrpe
  - bash
  - cron
  - nrpe
  - pysc.nrpe
  - raven.nrpe
  - requests.nrpe
  - rsyslog.nrpe
  - sudo
  - sudo.nrpe

sudo_salt_minion_nrpe:
  file:
    - managed
    - name: /etc/sudoers.d/salt_minion_nrpe
    - template: jinja
    - source: salt://salt/minion/nrpe/sudo.jinja2
    - mode: 440
    - user: root
    - group: root
    - require:
      - pkg: sudo

{%- if not salt['data.get']('returner_timestamps_last_success') %}
set_last_success_timestamp:
  module:
    - run
    - name: data.update
    - key: 'returner_timestamps_last_success'
    - value: '{{ salt['status.current_time']() }}'
    - require_in:
      - file: /usr/lib/nagios/plugins/check_minion_last_success.py
{%- endif %}

/usr/lib/nagios/plugins/check_minion_last_success.py:
  file:
    - managed
    - source: salt://salt/minion/nrpe/check_last_success.py
    - user: root
    - group: nagios
    - mode: 550
    - require:
      - module: nrpe-virtualenv
      - pkg: nagios-nrpe-server
      - file: nsca-salt.minion
      - file: sudo_salt_minion_nrpe
    - require_in:
      - service: nagios-nrpe-server
      - service: nsca_passive

/usr/lib/nagios/plugins/check_minion_pillar_render.py:
  file:
    - managed
    - source: salt://salt/minion/nrpe/check_pillar.py
    - user: root
    - group: nagios
    - mode: 550
    - require:
      - module: nrpe-virtualenv
      - pkg: nagios-nrpe-server
      - file: nsca-salt.minion
    - require_in:
      - service: nagios-nrpe-server
      - service: nsca_passive

{{ passive_check('salt.minion') }}

salt_minion_pillar_render_cron:
  file:
    - managed
    - name: /etc/cron.twice_daily/salt_minion_pillar_render
    - source: salt://salt/minion/nrpe/cron.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 500
    - require:
      - file: bash
      - file: /etc/cron.twice_daily
      - file: /usr/lib/nagios/plugins/check_minion_pillar_render.py
