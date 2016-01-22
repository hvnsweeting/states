{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'cron/macro.jinja2' import test_cron with context %}
{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}
include:
  - doc
  - hostname
  - taiga
  - taiga.backup
  - taiga.backup.diamond
  - taiga.backup.nrpe
  - taiga.diamond
  - taiga.nrpe

{%- call test_cron() %}
- sls: taiga
- sls: taiga.backup
- sls: taiga.backup.diamond
- sls: taiga.backup.nrpe
- sls: taiga.diamond
- sls: taiga.nrpe
{%- endcall %}

test:
  monitoring:
    - run_all_checks
    - wait: 10
    - order: last
    - require:
      - cmd: test_crons
      - host: hostname
  qa:
    - test
    - name: taiga
    - additional:
      - taiga.backup
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
  diamond:
    - test
    - map:
        ProcessResources:
    {{ diamond_process_test('uwsgi-taiga') }}
    - require:
      - sls: taiga
      - sls: taiga.diamond
