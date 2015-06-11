{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - clamav.server
  - clamav.server.nrpe
  - clamav.server.diamond
  - doc

{%- from 'cron/macro.jinja2' import test_cron with context %}
{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}

{%- call test_cron() %}
- sls: clamav
- sls: clamav.server.nrpe
- sls: clamav.server.diamond
{%- endcall %}

test:
  monitoring:
    - run_all_checks
    - wait: 60
    - order: last
    - require:
      - cmd: test_crons
  diamond:
    - test
    - map:
        ProcessResources:
    {{ diamond_process_test('clamav') }}
    {{ diamond_process_test('freshclam') }}
    - require:
      - sls: clamav.server
      - sls: clamav.server.diamond
  qa:
    - test_pillar
    - name: clamav
    - additional:
      - clamav.server
    - pillar_doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc

test_clamav_server:
  qa:
    - test_monitor
    - name: clamav.server
    - monitor_doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
