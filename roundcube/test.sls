{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'cron/macro.jinja2' import test_cron with context %}
{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}
{%- from 'fail2ban/macro.jinja2' import fail2ban_regex_test with context %}
include:
  - doc
  - logrotate
  - roundcube
  - roundcube.backup
  - roundcube.backup.diamond
  - roundcube.backup.nrpe
  - roundcube.diamond
  - roundcube.fail2ban
  - roundcube.fail2ban.diamond
  - roundcube.nrpe

{%- call test_cron() %}
- sls: roundcube
- sls: roundcube.backup
- sls: roundcube.backup.diamond
- sls: roundcube.backup.nrpe
- sls: roundcube.diamond
- sls: roundcube.fail2ban
- sls: roundcube.fail2ban.diamond
- sls: roundcube.nrpe
{%- endcall %}

{{ fail2ban_regex_test('roundcube', jail='roundcube-auth', message="IMAP Error: Login failed for root from 5.6.7.8") }}

test:
  monitoring:
    - run_all_checks
    - wait: 30
    - order: last
    - require:
      - cmd: test_crons
  cmd:
    {# ensuring that apache2 was not installed #}
    - run
    - name: false
    - onlyif: dpkg -l 'apache2'
    - require:
      - monitoring: test
  qa:
    - test
    - name: roundcube
    - additional:
      - roundcube.backup
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
  diamond:
    - test
    - map:
        UserScripts:
          fail2ban.roundcube-auth: True
    - require:
      - sls: roundcube
      - sls: roundcube.diamond
