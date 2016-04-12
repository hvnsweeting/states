{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'cron/macro.jinja2' import test_cron with context %}

include:
  - sslyze
  - sslyze.nrpe

{%- call test_cron() %}
- sls: sslyze
- sls: sslyze.nrpe
{%- endcall %}

nsca-test:
  file:
    - managed
    - name: /etc/nagios/nsca.d/test.yml
    - require:
      - file: /etc/nagios/nsca.d
    - contents: |
        sslyze:
          command: /usr/lib/nagios/plugins/check_ssl_configuration.py --formula=test --check=sslyze
          arguments:
            host: mail.google.com

test:
  monitoring:
    - run_all_checks
    - order: last
    - require:
      - cmd: test_crons
  file:
    - absent
    - name: /etc/nagios/nsca.d/test.yml
    - require:
      - monitoring: test
