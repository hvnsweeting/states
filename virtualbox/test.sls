{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'cron/macro.jinja2' import test_cron with context %}

include:
  - doc
  - virtualbox
  - virtualbox.nrpe

{%- call test_cron() %}
- sls: virtualbox
- sls: virtualbox.nrpe
{%- endcall %}

test:
  monitoring:
    - run_all_checks
    - wait: 60
    - order: last
    - require:
      - cmd: test_crons
  qa:
    - test
    - name: virtualbox
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
