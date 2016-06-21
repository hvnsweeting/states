{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

backup_replicate:
  file:
    - absent
    - name: /var/lib/backup

/etc/cron.daily/backup_replicate:
  file:
    - absent
