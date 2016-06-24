{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - bash
  - cron

backup_rotator:
  file:
    - managed
    - name: /usr/local/bin/backup-rotator
    - user: root
    - group: root
    - mode: 555
    - source: salt://backup/server/ssh/rotator.py

backup_rotate_weekly:
  file:
    - managed
    - name: /etc/cron.weekly/backup-rotate
    - user: root
    - group: root
    - mode: 500
    - template: jinja
    - source: salt://backup/server/ssh/rotate.jinja2
    - context:
        from_dir: ''
        to_dir: weekly
    - require:
      - pkg: cron
      - file: bash
      - file: backup_rotator

backup_rotate_monthly:
  file:
    - managed
    - name: /etc/cron.monthly/backup-rotate
    - user: root
    - group: root
    - mode: 500
    - template: jinja
    - source: salt://backup/server/ssh/rotate.jinja2
    - context:
        from_dir: weekly
        to_dir: monthly
    - require:
      - pkg: cron
      - file: bash
      - file: backup_rotator

cleanup-old-archive:
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
