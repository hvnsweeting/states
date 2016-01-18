{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt.nrpe
  - backup.client.{{ salt['pillar.get']('backup_storage') }}.nrpe
  - bash.nrpe
  - cron.nrpe
  - nrpe
  - orientdb.nrpe

{%- from 'nrpe/passive.jinja2' import passive_check with context %}
{{ passive_check('orientdb.backup') }}

extend:
  check_backup.py:
    file:
      - require:
        - file: nsca-orientdb.backup
