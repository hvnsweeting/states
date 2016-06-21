{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - rsyslog
  - xinetd
  - rsync.common

/etc/xinetd.d/rsync:
  file:
    - managed
    - source: salt://rsync/xinetd.jinja2
    - template: jinja
    - mode: 440
    - user: root
    - group: root
    - context:
        per_source: {{ salt['pillar.get']('rsync:limit_per_ip', '"UNLIMITED"') }}
    - require:
      - file: /etc/xinetd.d
      - file: rsync
    - watch_in:
      - service: xinetd

/etc/rsyncd.conf:
  file:
    - managed
    - user: root
    - group: root
    - mode: 440
    - template: jinja
    - source: salt://rsync/config.jinja2
    - require:
      - pkg: rsync
      - file: rsync
    - watch_in:
      - service: xinetd
