{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - backup.client
  - bash
  - cron
  - postgresql.server.backup

backup-mattermost:
  file:
    - managed
    - name: /etc/cron.daily/backup-mattermost
    - user: root
    - group: root
    - mode: 500
    - template: jinja
    - source: salt://mattermost/backup/cron.jinja2
    - require:
      - pkg: cron
      - file: /usr/local/bin/backup-postgresql
      - file: bash
      - file: /usr/local/share/salt_common.sh
      - file: /usr/local/bin/backup-file
