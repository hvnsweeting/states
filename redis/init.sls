{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt

{%- from 'macros.jinja2' import manage_pid with context %}
{%- from "os.jinja2" import os with context %}
{%- set files_archive = salt['pillar.get']('files_archive', False) %}

redis:
  pkgrepo:
    - managed
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/redis {{ grains['oscodename'] }} main
    - key_url: salt://redis/key.gpg
{%- else %}
    - ppa: chris-lea/redis
{%- endif %}
    - file: /etc/apt/sources.list.d/chris-lea-redis-server.list
    - clean_file: True
    - require:
      - cmd: apt_sources
  pkg:
    - installed
    - name: redis-server
    - require:
      - pkgrepo: redis
  user:
    - present
    - shell: /bin/false
    - require:
      - pkg: redis
  file:
    - managed
    - template: jinja
    - source: salt://redis/config.jinja2
    - name: /etc/redis/redis.conf
    - user: root
    - group: redis
    - mode: 440
    - require:
      - pkg: redis
  service:
    - running
    - enable: True
    - name: redis-server
    - order: 50
    - watch:
      - file: redis
      - file: /etc/init.d/redis-server
      - pkg: redis
      - user: redis

{%- set file_max = salt['pillar.get']('sysctl:fs.file-max', False) %}
{%- if file_max %}
/etc/default/redis-server:
  file:
    - managed
    - contents: |
        # {{ salt['pillar.get']('message_do_not_modify') }}

        ULIMIT={{ file_max }}
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: redis
    - watch_in:
      - service: redis
{%- endif %}

/etc/init.d/redis-server:
  file:
    - managed
    - source: salt://redis/sysvinit.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 550
    - require:
      - pkg: redis

{%- call manage_pid('/var/run/redis/redis-server.pid', 'redis', 'redis', 'redis-server') %}
- pkg: redis
{%- endcall %}
