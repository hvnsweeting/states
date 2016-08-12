{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'cron/macro.jinja2' import test_cron with context %}
{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}
include:
  - doc
  - grafana
  - grafana.backup
  - grafana.backup.diamond
  - grafana.backup.nrpe
  - grafana.diamond
  - grafana.nrpe

{%- call test_cron() %}
- sls: grafana
- sls: grafana.backup
- sls: grafana.backup.nrpe
- sls: grafana.diamond
- sls: grafana.nrpe
{%- endcall %}

test:
  diamond:
    - test
    - map:
        ProcessResources:
    {{ diamond_process_test('grafana') }}
    - require:
      - sls: grafana
      - sls: grafana.diamond
  monitoring:
    - run_all_checks
    - order: last
    - require:
      - cmd: test_crons
  qa:
    - test
    - name: grafana
    - additional:
      - grafana.backup
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
