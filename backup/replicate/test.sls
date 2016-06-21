{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - doc
  - backup.replicate
  - backup.replicate.diamond
  - backup.replicate.nrpe

test:
  monitoring:
    - run_all_checks
    - order: last
  qa:
    - test_pillar
    - name: backup.replicate
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
