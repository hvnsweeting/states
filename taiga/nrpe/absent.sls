{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'nrpe/passive.jinja2' import passive_absent with context %}
{{ passive_absent('taiga') }}

/etc/nagios/nrpe.d/taiga-nginx.cfg:
  file:
    - absent

/etc/nagios/nrpe.d/postgresql-taiga.cfg:
  file:
    - absent

/usr/lib/nagios/plugins/check_taiga_events.py:
  file:
    - absent

/etc/cron.hourly/taiga-monitoring:
  file:
    - absent
