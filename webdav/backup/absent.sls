{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

backup-webdav:
  file:
    - absent
    - name: /etc/cron.daily/backup-webdav
