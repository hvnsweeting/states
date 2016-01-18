{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set formula = 'discourse' -%}
{%- from 'nrpe/passive.jinja2' import passive_check with context %}
include:
  - apt.nrpe
  - docker.nrpe
  - discourse
  - postgresql.server.nrpe
  - redis.nrpe
{%- if salt['pillar.get']('discourse:ssl', False) %}
  - ssl.nrpe
{%- endif %}
  - sudo.nrpe

{{ passive_check('discourse', check_ssl_score=True) }}

extend:
  check_psql_encoding.py:
    file:
      - require:
        - file: nsca-{{ formula }}
        - postgres_database: discourse
  /usr/lib/nagios/plugins/check_pgsql_query.py:
    file:
      - require:
        - file: nsca-{{ formula }}
        - postgres_database: discourse
