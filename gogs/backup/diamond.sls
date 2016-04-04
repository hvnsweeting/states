{#- Usage of this is governed by a license that can be found in doc/license.rst -#}
{%- from "postgresql/server/backup/diamond.jinja2" import postgresql_backup_diamond with context -%}

include:
  - diamond
  - cron.diamond
  - backup.diamond
  - gogs.diamond

gogs_backup_file_diamond_resources:
  file:
    - accumulated
    - name: processes
    - template: jinja
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[backup-gogs]]
        cmdline = ^/usr/local/bin/backup-file gogs /var/lib

{{ postgresql_backup_diamond('gogs') }}
