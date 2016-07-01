{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'cron/macro.jinja2' import test_cron with context %}
{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}
include:
  - doc
  - mattermost
  - mattermost.backup
  - mattermost.backup.diamond
  - mattermost.backup.nrpe
  - mattermost.diamond
  - mattermost.nrpe

{%- call test_cron() %}
- sls: mattermost
- sls: mattermost.backup
- sls: mattermost.backup.nrpe
- sls: mattermost.diamond
- sls: mattermost.nrpe
{%- endcall %}

test:
  diamond:
    - test
    - map:
        ProcessResources:
    {{ diamond_process_test('mattermost') }}
    - require:
      - sls: mattermost
      - sls: mattermost.diamond
  monitoring:
    - run_all_checks
    - order: last
    - require:
      - cmd: test_crons
  qa:
    - test
    - name: mattermost
    - additional:
      - mattermost.backup
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
