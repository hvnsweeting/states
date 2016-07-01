{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - backup.client.{{ salt['pillar.get']('backup_storage') }}.nrpe
  - bash.nrpe
  - cron.nrpe
  - nrpe

{%- from 'nrpe/passive.jinja2' import passive_check with context -%}
{{ passive_check('webdav.backup') }}

extend:
  check_backup.py:
    file:
      - require:
        - file: nsca-webdav.backup
