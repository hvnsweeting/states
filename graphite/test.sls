{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'cron/macro.jinja2' import test_cron with context %}
{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}
include:
  - doc
  - graphite
  - graphite.backup
  - graphite.backup.diamond
  - graphite.backup.nrpe
  - graphite.diamond
  - graphite.nrpe

{%- call test_cron() %}
- sls: graphite
- sls: graphite.backup
- sls: graphite.backup.diamond
- sls: graphite.backup.nrpe
- sls: graphite.diamond
- sls: graphite.nrpe
{%- endcall %}

test:
  monitoring:
    - run_all_checks
    - order: last
    - require:
      - cmd: test_crons
  qa:
    - test
    - name: graphite
    - additional:
      - graphite.backup
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
  diamond:
    - test
    - map:
        ProcessResources:
    {{ diamond_process_test('uwsgi-graphite', zmempct=False) }}
    - require:
      - sls: graphite
      - sls: graphite.diamond
