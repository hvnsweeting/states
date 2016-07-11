{%- from 'upstart/rsyslog.jinja2' import manage_upstart_log with context -%}
{%- set ssl = salt['pillar.get']('webdav:ssl', False) %}
include:
  - apt
  - local
  - rsyslog
{% if ssl %}
  - ssl
{% endif %}

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- set version = '1.0.0' %}
{%- set md5_hash = '2ba01e8776df002138600378e01bd25c' %}

/usr/local/webdav:
  file:
    - directory
    - user: root
    - group: webdav
    - mode: 550
    - require:
      - user: webdav
      - file: /usr/local

webdav:
  user:
    - present
    - name: webdav
    - gid_from_name: True
    - system: True
    - fullname: webdav
    - shell: /usr/sbin/nologin
    - home: /var/lib/webdav
    - createhome: True
    - password: "*"
    - enforce_password: True
  archive:
    - extracted
    - name: /usr/local/webdav
{%- if files_archive %}
    - source: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/webdav-{{ version }}.tar.gz
{%- else %}
{%- endif %}
    - source_hash: md5={{ md5_hash }}
    - archive_format: tar
    - tar_options: z
    - if_missing: /usr/local/webdav/salt_webdav_{{ version }}
    - require:
      - user: webdav
      - file: /usr/local/webdav
  file:
    - managed
    - name: /etc/init/webdav.conf
    - user: root
    - group: root
    - source: salt://webdav/upstart.jinja2
    - template: jinja
  service:
    - running
    - name: webdav
    - enable: True
    - require:
      - cmd: webdav_version_manage
      - file: /var/log/webdav
      - file: /var/lib/webdav
    - watch:
      - file: webdav
      - file: webdav_config
      - archive: webdav
      - file: webdav_version_manage

webdav_allow_bind_to_privileged_port:
  pkg:
    - installed
    - name: libcap2-bin
    - require:
      - cmd: apt_sources
  cmd:
    - run
    - name: setcap 'cap_net_bind_service=+ep' /usr/local/webdav/webdav
    - unless: 'getcap /usr/local/webdav/webdav | grep cap_net_bind_service+ep'
    - require:
      - archive: webdav
      - pkg: webdav_allow_bind_to_privileged_port
    - require_in:
      - service: webdav

webdav_version_manage:
  file:
    - managed
    - replace: False
    - name: /usr/local/webdav/salt_webdav_{{ version }}
    - require:
      - archive: webdav
  cmd:
    - run
    - name: find /usr/local/webdav/ -maxdepth 1 -mindepth 1 -type f -name 'salt_webdav_*' ! -name 'salt_webdav_{{ version }}' -delete
    - require:
      - archive: webdav
      - file: webdav_version_manage

/etc/webdav:
  file:
    - directory
    - user: root
    - group: webdav
    - require:
      - user: webdav

webdav_config:
  file:
    - serialize
    - mode: 440
    - formatter: JSON
    - dataset:
        metrics:
          disable: false
          carbon:
          {%- set graphite_address = salt['pillar.get']('graphite_address', False) %}
          {%- if graphite_address %}
            address: {{ salt['dig.A'](graphite_address) }}
            port: "2003"
            interval: 60000000000
            hostname: {{ grains['id'] }}
          {%- endif %}
          go: true
          go_interval: 60000000000
          hostname: {{ grains['id'] }}
        logging:
         {%- set sentry_dsn = salt['pillar.get']('sentry_dsn', False) %}
         {%- if sentry_dsn %}
          sentry:
            dsn: "{{ sentry_dsn }}"
            tags:
              application: webdav
            level: {{ salt['pillar.get']('webdav:logging_level', 'warning') }}
         {%- endif %}
          syslog:
            tag: webdav
          tags:
            application: webdav
          level: {{ salt['pillar.get']('webdav:logging_level', 'warning') }}
       {%- set graylog2_address = salt['pillar.get']('graylog2_address', False) %}
       {%- if graylog2_address %}
          graylog:
            address: {{ graylog2_address }}
            port: "12201"
            facility: webdav
       {%- endif %}
          runmode: prod
        daemon:
          root: /var/lib/webdav
          realm: devcats
          server:
            https:
              address: 0.0.0.0
              port: "443"
              certificate: |-
                {{ salt['pillar.get']('ssl:certs:' + ssl + ':server_crt')|indent(16, indentfirst=False) }}
                {{ salt['pillar.get']('ssl:certs:' + ssl + ':ca_crt')|indent(16, indentfirst=False) }}
              key: |-
                {{ salt['pillar.get']('ssl:certs:' + ssl + ':server_key')|indent(16, indentfirst=False) }}
              server_name: {{ salt["pillar.get"]("webdav:server_name") }}
              timeout: 0
          {%- for username, hash in salt['pillar.get']('webdav:users', {}).iteritems() %}
            {%- if loop.index0 == 0 %}
          users:
            {%- endif %}
            - username: {{ username }}
              hash: {{ hash }}
          {%- endfor %}

    - name: /etc/webdav/config.json
    - user: root
    - group: webdav
    - require:
      - user: webdav
      - file: /etc/webdav

/var/log/webdav:
  file:
    - directory
    - user: root
    - group: webdav
    - mode: 770

/var/lib/webdav:
  file:
    - directory
    - user: root
    - group: webdav
    - mode: 770

{{ manage_upstart_log('webdav') }}
