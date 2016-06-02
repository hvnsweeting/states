{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - postgresql.server
  - hostname
  - rsyslog
  - web

proftpd:
  debconf:
    - set
    - data:
        'shared/proftpd/inetd_or_standalone': {'type': 'select', 'value': 'standalone'}
    - require:
      - pkg: apt_sources
  pkg:
    - installed
    - name: proftpd-basic
    - require:
      - debconf: proftpd
      - cmd: apt_sources
  file:
    - managed
    - name: /etc/proftpd/proftpd.conf
    - template: jinja
    - source: salt://proftpd/config.jinja2
    - user: root
    - group: root
    - mode: 440
    - show_diff: False
    - require:
      - pkg: proftpd
  service:
    - running
    - enable: True
    - order: 50
    - require:
      - host: hostname
      - postgres_database: proftpd-mod-pgsql
      - cmd: proftpd-users
      - service: postgresql
      - service: rsyslog
      - file: web
    - watch:
      - file: proftpd
      - pkg: proftpd-mod-pgsql
      - pkg: proftpd
      - file: proftpd_sysv

proftpd_sysv:
  file:
    - managed
    - name: /etc/init.d/proftpd
    - source: salt://proftpd/sysv.jinja2
    - user: root
    - group: root
    - mode: 750
    - require:
      - pkg: proftpd

proftpd-mod-pgsql:
  pkg:
    - installed
    - require:
      - pkg: proftpd
      - cmd: apt_sources
  postgres_user:
    - present
{%- set username = salt['pillar.get']('proftpd:db:username', 'proftpd') %}
    - name: {{ username }}
    - password: {{ salt['password.pillar']('proftpd:db:password', 10) }}
    - user: postgres
    - require:
      - service: postgresql
  postgres_database:
    - present
    - name: {{ salt['pillar.get']('proftpd:db:name', 'proftpd') }}
    - owner: {{ username }}
    - user: postgres
    - require:
      - postgres_user: proftpd-mod-pgsql

proftpd-users:
  file:
    - managed
    - name: {{ opts['cachedir'] }}/proftpd.sql
    - user: postgres
    - group: postgres
    - mode: 440
    - template: jinja
    - source: salt://proftpd/sql.jinja2
    - require:
      - pkg: postgresql
  cmd:
    - wait
    - name: cat {{ opts['cachedir'] }}/proftpd.sql | su - postgres -s /bin/bash -c 'psql proftpd'
    - user: root
    - group: root
    - require:
      - postgres_database: proftpd-mod-pgsql
      - service: postgresql
    - watch:
      - file: proftpd-users

{% for file in ('virtuals', 'tls', 'sql', 'modules', 'ldap') %}
/etc/proftpd/{{ file }}.conf:
  file:
    - absent
    - require:
      - pkg: proftpd
    - watch_in:
      - service: proftpd
{% endfor %}

/var/log/proftpd/xferlog:
  file:
    - absent
    - require:
      - pkg: proftpd

{% for account in salt['pillar.get']('proftpd:accounts', {}) %}
/var/lib/deployments/{{ account }}/static/ftp:
  file:
    - directory
    - user: www-data
    - group: www-data
    - mode: 770
    - makedirs: True
    - require:
      - file: web
    - require_in:
      - service: proftpd
{% endfor %}
