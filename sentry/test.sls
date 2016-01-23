{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'cron/macro.jinja2' import test_cron with context %}
{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}
include:
  - doc
  - hostname
  - sentry
  - sentry.backup
  - sentry.backup.diamond
  - sentry.backup.nrpe
  - sentry.diamond
  - sentry.nrpe

{%- call test_cron() %}
- sls: sentry
- sls: sentry.backup
- sls: sentry.backup.diamond
- sls: sentry.backup.nrpe
- sls: sentry.diamond
- sls: sentry.nrpe
{%- endcall %}

test:
  monitoring:
    - run_all_checks
    - wait: 60
    - order: last
    - require:
      - cmd: test_crons
      - host: hostname
  qa:
    - test
    - name: sentry
    - additional:
      - sentry.backup
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
  diamond:
    - test
    - map:
        ProcessResources:
          {{ diamond_process_test('uwsgi-sentry') }}
          {{ diamond_process_test('sentry-worker') }}
          {{ diamond_process_test('sentry-beat') }}
    - require:
      - sls: sentry
      - sls: sentry.diamond
