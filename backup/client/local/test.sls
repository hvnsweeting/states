{#- Usage of this is governed by a license that can be found in doc/license.rst -#}
include:
  - backup.client.local
  - backup.client.local.diamond
  - backup.client.local.nrpe
  - backup.dumb
  - doc

test_check_backup:
  cmd:
    - run
    - name: /usr/local/bin/backup-store `/usr/local/bin/create_dumb`
    - require:
      - file: /usr/local/bin/backup-store
      - file: /usr/local/bin/create_dumb
  file:
    - managed
    - name: /etc/nagios/nsca.d/backup.client.local.yml
    - contents: |
        test_check_backup:
          command: /usr/lib/nagios/plugins/check_backup.py --formula=backup.client.local --check=test_check_backup
          arguments:
            facility: backup-client-test
    - require:
      - file: /etc/nagios/nsca.d
      - sls: backup.client.local.nrpe
  monitoring:
    - run_check
    - name: test_check_backup
    - require:
      - cmd: test_check_backup
      - file: test_check_backup

clean_test_check_backup:
  file:
    - absent
    - name: {{ salt["pillar.get"]("backup:local:path") }}
    - require:
      - monitoring: test_check_backup
  {#- Do not use file.absent --> nsca_passive will be restarted
  which caused recursive requisite #}
  module:
    - run
    - name: file.remove
    - path: /etc/nagios/nsca.d/backup.client.local.yml
    - require:
      - monitoring: test_check_backup

test:
  monitoring:
    - run_all_checks
    - require:
      - sls: backup.client.local
      - sls: backup.client.local.nrpe
  qa:
    - test_pillar
    - name: backup.client.local
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
