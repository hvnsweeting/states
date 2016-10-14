{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - cron
  - rsyslog
  - ssh.client
  - rsync.common

backup_replicate:
  file:
    - directory
    - name: /var/lib/backup
    - user: root
    - group: root
    - mode: 775

/etc/cron.daily/backup_replicate:
  file:
    - managed
    - source: salt://backup/replicate/cron.jinja2
    - template: jinja
    - mode: 500
    - user: root
    - group: root
    - require:
      - pkg: cron
      - service: rsyslog
      - file: backup_replicate
      - file: rsync

backup_replicate_cleanup_old_archive:
  file:
    - managed
    - name: /etc/cron.daily/backup-server-ssh
    - user: root
    - group: root
    - mode: 500
    - template: jinja
    - source: salt://backup/server/ssh/cron.jinja2
    - require:
      - pkg: cron
      - file: bash
