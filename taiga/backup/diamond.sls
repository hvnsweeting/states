{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - backup.diamond
  - cron.diamond

{%- from "postgresql/server/backup/diamond.jinja2" import postgresql_backup_diamond with context -%}
{{ postgresql_backup_diamond('taiga') }}
