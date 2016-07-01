{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}
include:
  - doc
  - webdav
  - webdav.backup
  - webdav.backup.diamond
  - webdav.backup.nrpe
  - webdav.diamond
  - webdav.nrpe

test:
  diamond:
    - test
    - map:
        ProcessResources:
    {{ diamond_process_test('webdav') }}
    - require:
      - sls: webdav
      - sls: webdav.diamond
  monitoring:
    - run_all_checks
    - order: last
  qa:
    - test
    - name: webdav
    - additional:
      - webdav.backup
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
