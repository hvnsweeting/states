{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'upstart/rsyslog.jinja2' import manage_upstart_log with context -%}
{%- from 'macros.jinja2' import manage_pid with context %}
{%- set ssl = salt['pillar.get']('youtrack:ssl', False) %}

include:
  - apt
  - java.7
  - local
  - nginx
  - rsyslog
{% if ssl %}
  - ssl
{% endif %}

/var/lib/youtrack:
  file:
    - directory
    - user: youtrack
    - group: youtrack
    - mode: 750
    - require:
      - user: youtrack

/usr/local/youtrack:
  file:
    - directory
    - user: root
    - group: youtrack
    - mode: 750
    - require:
      - file: /usr/local

/etc/nginx/conf.d/youtrack.conf:
  file:
    - managed
    - template: jinja
    - source: salt://youtrack/nginx.jinja2
    - user: root
    - group: www-data
    - context:
        appname: youtrack
        root: /var/lib/youtrack
        statics: [] {# JAR will serve it itself, no path for serving by NGINX #}
    - mode: 440
    - require:
      - pkg: nginx
      - process: youtrack
    - watch_in:
      - service: nginx

{%- set files_archive = salt['pillar.get']('files_archive', False)|default('http://archive.robotinfra.com', boolean=True) %}
{%- set jarfile = 'youtrack-6.5.17105.jar' %}

youtrack_jar:
  file:
    - managed
    - name: /usr/local/youtrack/{{ jarfile }}
    - source: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/{{ jarfile }}
    - source_hash: sha256=d72cc559202c5301bfa5bb3396018389e8ece691663320b4a83fd668a629737c
    - user: root
    - group: youtrack
    - mode: 440
    - require:
      - user: youtrack
      - file: /usr/local/youtrack
      - file: /var/lib/youtrack

/etc/youtrack:
  file:
    - directory
    - template: jinja
    - user: root
    - group: youtrack
    - mode: 750
    - require:
      - user: youtrack

/etc/youtrack/log4j.xml:
  file:
    - managed
    - template: jinja
    - user: root
    - group: youtrack
    - mode: 440
    - source: salt://youtrack/log4j.jinja2
    - require:
      - user: youtrack
      - file: /etc/youtrack

youtrack:
  user:
    - present
    - name: youtrack
    - home: /var/lib/youtrack
    - shell: /bin/false
  file:
    - managed
    - name: /etc/init/youtrack.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://youtrack/upstart.jinja2
    - context:
        jarfile: {{ jarfile }}
  service:
    - running
    - watch:
      - file: /var/lib/youtrack
      - file: youtrack
      - file: /etc/youtrack
      - file: /etc/youtrack/log4j.xml
      - user: youtrack
      - pkg: jre-7
      - file: jre-7
      - file: youtrack_jar
  process:
    - wait_socket
    - port: 8082
    - timeout: 60
    - require:
      - service: youtrack

{{ manage_upstart_log('youtrack') }}

{%- if ssl %}
extend:
  nginx.conf:
    file:
      - context:
          ssl: {{ ssl }}
  nginx:
    service:
      - watch:
        - cmd: ssl_cert_and_key_for_{{ ssl }}
{%- endif %}
