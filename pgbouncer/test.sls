{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}
include:
  - doc
  - pgbouncer
  - pgbouncer.diamond
  - pgbouncer.nrpe
  - postgresql.server

{%- for db, values in salt['pillar.get']('pgbouncer:databases').iteritems() %}
pgbouncer_{{ db }}:
  postgres_user:
    - present
    - name: {{ values['username'] }}
    - password: {{ values['password'] }}
    - superuser: True
    - user: postgres
    - require:
      - pkg: pgbouncer
      - service: postgresql
  postgres_database:
    - present
    - name: {{ values['dbname']|default(db) }}
    - owner: {{ values['username'] }}
    - user: postgres
    - require:
      - postgres_user: pgbouncer_{{ db }}
{%- endfor %}

test:
  cmd:
    - run
    - name: /usr/sbin/pgbouncer -R -d /etc/pgbouncer/pgbouncer.ini
    - user: postgres
    - require:
      - sls: pgbouncer
  monitoring:
    - run_all_checks
    - order: last
  diamond:
    - test
    - map:
        ProcessResources:
          {{ diamond_process_test('pgbouncer') }}
    - require:
      - sls: pgbouncer
      - service: diamond
  qa:
    - test
    - name: pgbouncer
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
