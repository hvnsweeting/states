{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - doc
  - acmetool
  - acmetool.nrpe

test:
  qa:
    - test_pillar
    - name: acmetool
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - cmd: doc
