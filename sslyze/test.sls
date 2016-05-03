{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'cron/macro.jinja2' import test_cron with context %}

include:
  - sslyze
  - sslyze.nrpe

{%- call test_cron() %}
- sls: sslyze
- sls: sslyze.nrpe
{%- endcall %}

/etc/nagios/nsca.d/test.yml:
  file:
    - managed
    - contents: |
        sslyze:
          command: /usr/lib/nagios/plugins/check_ssl_configuration.py --formula=test --check=sslyze
          arguments:
            host: mail.google.com
    - require:
      - file: /etc/nagios/nsca.d

test:
  monitoring:
    - run_all_checks
    - order: last
    - require:
      - cmd: test_crons
  {#- Do not use file.absent --> nsca_passive will be restarted
  which caused recursive requisite #}
  module:
    - run
    - name: file.remove
    - path: /etc/nagios/nsca.d/test.yml
    - require:
      - monitoring: test
