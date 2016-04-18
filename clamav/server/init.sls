{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'macros.jinja2' import manage_pid with context %}

include:
  - clamav

{%- call manage_pid('/var/run/clamav/freshclam.pid', 'clamav', 'clamav', 'clamav-freshclam', 660) %}
- pkg: clamav-freshclam
{%- endcall %}

{%- if salt['pillar.get']('clamav:mode', 'local') == "local" -%}
  {%- set daemon_user = "clamav" -%}
{%- else -%}
  {%- set daemon_user = "root" -%}
{%- endif %}

{%- call manage_pid('/var/run/clamav/clamd.pid', daemon_user, daemon_user, 'clamav-daemon', 664) %}
- pkg: clamav-daemon
{%- endcall %}

/etc/clamav/onerrorexecute.d/err-dbvirus-mail.sh:
  file:
    - managed
    - source: salt://clamav/err_mail.jinja2
    - template: jinja
    - user: root
    - group: clamav
    - mode: 550
    - require:
      - pkg: clamav-freshclam
      - user: clamav

extend:
  clamav-freshclam:
    file:
      - managed
      - name: /etc/clamav/freshclam.conf
      - source: salt://clamav/freshclam.jinja2
      - template: jinja
      - mode: 440
      - user: root
      - group: clamav
      - require:
        - pkg: clamav-freshclam
    cmd:
      - wait
      {#- on the very first run, it may say it cannot notify clamd, it's normal,
      because clamd cannot run without a db, which is provided by running this cmd #}
      - name: freshclam --stdout -v
      - require:
        - file: clamav-freshclam
        - module: clamav-freshclam
        - file: /etc/clamav/onerrorexecute.d/err-dbvirus-mail.sh
      - watch:
        - pkg: clamav-freshclam
        - user: clamav
    service:
      - running
      - order: 50
      - require:
        - cmd: clamav-freshclam
        - file: /etc/clamav/onerrorexecute.d/err-dbvirus-mail.sh
      - watch:
        - file: clamav-freshclam
        - pkg: clamav-freshclam
        - user: clamav
      - require_in:
        - file: /usr/local/bin/clamav-scan.sh
        - file: /var/lib/clamav/last-scan
  clamav-daemon:
    service:
      - running
      - order: 50
      - require:
        - service: clamav-freshclam
      - watch:
        - pkg: clamav-daemon
        - file: clamav-daemon
        - user: clamav
      - require_in:
        - file: /usr/local/bin/clamav-scan.sh
        - file: /var/lib/clamav/last-scan
