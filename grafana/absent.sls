{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

/usr/local/grafana:
  file:
    - absent
    - require:
      - service: grafana

/var/lib/grafana:
  file:
    - absent
    - require:
      - service: grafana

/var/log/grafana:
  file:
    - absent
    - require:
      - service: grafana

/etc/nginx/conf.d/grafana.conf:
  file:
    - absent
    - require:
      - service: grafana

grafana:
  pkg:
    - purged
  file:
    - absent
    - name: /etc/grafana/grafana.ini
    - require_in:
      - pkg: grafana
    - require:
      - service: grafana
  user:
    - absent
    - name: grafana
    - require:
      - service: grafana
  service:
    - dead
    - name: grafana-server

grafana_nginx_config:
  file:
    - absent
    - name: /etc/nginx/conf.d/grafana.conf
    - require:
      - service: grafana

grafana_sysv_files_absent:
  cmd:
    - run
    - name: update-rc.d -f grafana-server remove
    - require:
      - pkg: grafana

/etc/init.d/grafana-server:
  file:
    - absent
    - require:
      - cmd: grafana_sysv_files_absent
