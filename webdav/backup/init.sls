{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - backup.client
  - bash
  - cron

backup-webdav:
  file:
    - managed
    - name: /etc/cron.daily/backup-webdav
    - user: root
    - group: root
    - mode: 500
    - template: jinja
    - source: salt://webdav/backup/cron.jinja2
    - require:
      - pkg: cron
      - file: bash
      - file: /usr/local/share/salt_common.sh
      - file: /usr/local/bin/backup-file
