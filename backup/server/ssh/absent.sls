{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

cleanup-old-archive:
  file:
    - absent
    - name: /etc/cron.daily/backup-server-ssh

/etc/cron.daily/cleanup-old-archive:
  file:
    - absent

backup_rotator:
  file:
    - absent
    - name: /usr/local/bin/backup-rotator

backup_rotate_weekly:
  file:
    - absent
    - name: /etc/cron.weekly/backup-rotate

backup_rotate_monthly:
  file:
    - absent
    - name: /etc/cron.monthly/backup-rotate
