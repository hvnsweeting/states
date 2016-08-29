{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}
include:
  - doc
  - uwsgi
  - uwsgi.diamond
  - uwsgi.nrpe
  - uwsgi.php
  - uwsgi.top

test:
  monitoring:
    - run_all_checks
    - order: last
  qa:
    - test
    - name: uwsgi
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
  diamond:
    - test
    - map:
        ProcessResources:
          {{ diamond_process_test('uwsgi') }}
{%- set test = salt['pillar.get']('__test__', False) %}
{%- if test or (grains['virtual'] == 'kvm' and salt['file.file_exists']('/sys/kernel/mm/ksm/run')) %}
        KSM:
          ksm.full_scans: True
          ksm.pages_shared: True
          ksm.pages_sharing: True
          ksm.pages_to_scan: True
          ksm.pages_unshared: True
          ksm.pages_volatile: True
          ksm.run: True
          ksm.sleep_millisecs: True
{%- endif %}
    - require:
      - sls: uwsgi
      - sls: uwsgi.diamond
