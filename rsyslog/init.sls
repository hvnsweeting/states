{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "os.jinja2" import os with context %}

include:
  - apt
  - hostname

{%- set files_archive = salt['pillar.get']('files_archive', False) %}

{#- PID file owned by root, no need to manage #}
rsyslog:
{%- if os.is_precise %}
  pkgrepo:
    - managed
  {%- if not files_archive %}
    {%- set files_archive = "http://archive.robotinfra.com" %}
  {%- endif %}
    {#- source: ppa: tmortensen/rsyslogv7 #}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/rsyslog/7.4.4 {{ grains['oscodename'] }} main
    - key_url: salt://rsyslog/key.gpg
    - file: /etc/apt/sources.list.d/rsyslogv7.list
    - clean_file: True
    - require:
      - pkg: apt_sources
    - require_in:
      - pkg: rsyslog
{%- endif %}
  pkg:
    - installed
{%- if os.is_precise %}
    - version: 7.4.4-0ubuntu1ppa1
{%- endif %}
    - require:
      - cmd: apt_sources
      - host: hostname
  user:
    - present
    - name: syslog
    - shell: /bin/false
    - require:
      - pkg: rsyslog
  file:
    - managed
    - name: /etc/rsyslog.conf
    - mode: 440
    - template: jinja
    - source: salt://rsyslog/config.jinja2
    - require:
      - pkg: rsyslog
  service:
    - running
    - order: 50
    - watch:
      - pkg: rsyslog
      - file: rsyslog
      - file: /var/spool/rsyslog
      - user: rsyslog
      - file: /var/log/lastlog
      - file: /etc/init/rsyslog.conf

/etc/init/rsyslog.conf:
  file:
    - managed
    - source: salt://rsyslog/upstart.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: rsyslog

/var/log/lastlog:
  file:
    - managed
    - user: root
    - group: utmp
    - mode: 660
    - replace: False

/var/log/upstart:
  file:
    - directory
    - user: root
    - group: syslog {#- for reading upstart logs by rsyslog #}
    - mode: 750
    - file_mode: 640
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: rsyslog

/var/spool/rsyslog:
  file:
    - directory
    - mode: 755
    - user: syslog
    - require:
      - pkg: rsyslog

/etc/rsyslog.d/50-default.conf:
  file:
    - absent
    - require:
      - pkg: rsyslog
    - watch_in:
      - service: rsyslog

/etc/rsyslog.d/20-ufw.conf:
  file:
    - absent
    - require:
      - pkg: rsyslog
    - watch_in:
      - service: rsyslog

/etc/logrotate.d/rsyslog:
  file:
    - managed
    - template: jinja
    - source: salt://rsyslog/logrotate.jinja2
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: rsyslog
