{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set formula = 'roundcube' -%}
{%- from 'nrpe/passive.jinja2' import passive_check with context %}
include:
  - apt.nrpe
  - build.nrpe
  - nrpe
  - nginx.nrpe
  - postgresql.server.nrpe
  - php_fpm.nrpe
  - rsyslog.nrpe
{%- if salt['pillar.get'](formula + ':ssl', False) %}
  - ssl.nrpe
{%- endif %}

{{ passive_check(formula, check_ssl_score=True) }}

extend:
  check_psql_encoding.py:
    file:
      - require:
        - file: nsca-{{ formula }}
  /usr/lib/nagios/plugins/check_pgsql_query.py:
    file:
      - require:
        - file: nsca-{{ formula }}
