rsync:
  pkg:
    - installed
    - require:
      - cmd: apt_sources
  service:
    - dead
    - enable: False
    - require:
      - pkg: rsync
  file:
    - absent
    - name: /etc/init.d/rsync
    - require:
      - service: rsync
