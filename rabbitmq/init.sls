{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - erlang
  - logrotate
  - hostname
{%- set ssl = salt['pillar.get']('rabbitmq:ssl', False) %}
{%- if ssl %}
  - ssl
{%- endif %}
  - nginx
  - rsyslog

{% set master_id = salt['pillar.get']('rabbitmq:cluster:master') %}

rabbitmq:
  user:
    - present
    - shell: /bin/false
    - home: /var/lib/rabbitmq
    - password: "*"
    - enforce_password: True
    - gid_from_name: True

/var/lib/rabbitmq:
  file:
    - directory
    - user: rabbitmq
    - group: rabbitmq
    - mode: 700
    - require:
      - user: rabbitmq

{#
 Clustering requires the same cookie to be the same on all nodes.
 It need to be created BEFORE rabbitmq-server package is installed.
 If the cookie is changed while the daemon is running, it cannot be stopped
 using regular startup script and need to be manually killed.
#}

{%- set version = '3.1.2' %}
{%- set sub_version = version + '-1' %}
rabbitmq_erlang_cookie:
  file:
    - managed
    - name: /var/lib/rabbitmq/.erlang.cookie
    - template: jinja
    - user: rabbitmq
    - group: rabbitmq
    - mode: 400
    - contents: {{ salt['pillar.get']('rabbitmq:cluster:cookie') }}
    - require:
      - file: /var/lib/rabbitmq

{%- if salt['pkg.version']('rabbitmq-server') not in ('', sub_version) %}
rabbitmq_old_version:
  pkg:
    - removed
    - name: rabbitmq-server
    - require_in:
      - pkg: rabbitmq-server
{%- endif %}

{#- does not use PID, no need to manage #}

rabbitmq_config_file:
  file:
    - managed
    - name: /etc/rabbitmq/rabbitmq.config
    - template: jinja
    - user: root
    - group: rabbitmq
    - mode: 440
    - source: salt://rabbitmq/config.jinja2
    - require:
      - pkg: rabbitmq-server
      - user: rabbitmq

{%- for log_file in ("shutdown", "startup") %}
/etc/rsyslog.d/rabbitmq-{{ log_file }}.conf:
  file:
    - managed
    - mode: 440
    - source: salt://rsyslog/template.jinja2
    - template: jinja
    - require:
      - pkg: rsyslog
      - service: rabbitmq-server
    - watch_in:
      - service: rsyslog
    - context:
        file_path: /var/log/rabbitmq/{{ log_file }}_err
        tag_name: rabbitmq-{{ log_file }}
        severity: error
        facility: daemon
{%- endfor %}

rabbitmq-server:
  file:
    - directory
    - name: /etc/rabbitmq/rabbitmq.conf.d
    - mode: 550
    - user: rabbitmq
    - group: rabbitmq
    - require:
      - pkg: rabbitmq-server
      - user: rabbitmq
  service:
    - running
    - enable: True
    - order: 50
{# until https://github.com/saltstack/salt/issues/5027 is fixed, this is required #}
    - sig: beam{% if grains['num_cpus'] > 1 %}.smp{% endif %}
    - require:
      - pkg: rabbitmq-server
    - watch:
      - user: rabbitmq
      - file: rabbitmq-server
      - file: rabbitmq_config_file
      - rabbitmq_plugin: rabbitmq-server
{%- set nodes = salt['pillar.get']('rabbitmq:cluster:nodes') %}
{% for node in nodes %}
    {% if node != grains['id'] %}
      - host: host_{{ node }}
    {% endif %}
{% endfor %}
  rabbitmq_plugin:
    - runas: root
    - enabled
    - name: rabbitmq_management
    - require:
      - pkg: rabbitmq-server
  pkg:
    - installed
    - sources:
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
      - rabbitmq-server: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/rabbitmq-server_{{ sub_version }}_all.deb
{%- else %}
      - rabbitmq-server: http://www.rabbitmq.com/releases/rabbitmq-server/v{{ version }}/rabbitmq-server_{{ sub_version }}_all.deb
{%- endif %}
    - require:
      - pkg: erlang
      - cmd: apt_sources
      - pkg: logrotate
      - host: hostname
      - file: rabbitmq_erlang_cookie

{% if grains['id'] == master_id %}
  {% set vhosts = salt['pillar.get']('rabbitmq:vhosts', {}) %}
  {% for vhost in vhosts %}
rabbitmq-vhost-{{ vhost }}:
  rabbitmq_user:
    - present
    - runas: root
    - name: {{ vhost }}
    - password: {{ salt['pillar.get']('rabbitmq:vhosts:' ~ vhost) }}
    - force: True
    - require:
      - service: rabbitmq-server
  rabbitmq_vhost:
    - present
    - runas: root
    - name: {{ vhost }}
    - user: {{ vhost }}
    - require:
      - rabbitmq_user: rabbitmq-vhost-{{ vhost }}
  {% endfor %}

monitor_user:
  rabbitmq_user:
    - present
    - runas: root
    - name: {{ salt['pillar.get']('rabbitmq:monitor:user') }}
    - password: {{ salt['pillar.get']('rabbitmq:monitor:password', None)|default(salt['password.pillar']('rabbitmq:monitor:password'), boolean=True) }}
    - force: True
    - tags:
      - monitoring
    - perms:
      - '/':
        - ""
        - ""
        - ".*"
  {% for vhost in vhosts %}
    {%- if vhost != '/' %}
      - {{ vhost }}:
        - ""
        - ""
        - ".*"
    {%- endif %}
  {%- endfor %}
    - require:
  {% for vhost in vhosts %}
      - rabbitmq_vhost: rabbitmq-vhost-{{ vhost }}
  {%- endfor %}
      - service: rabbitmq-server

admin_user:
  rabbitmq_user:
    - present
    - runas: root
    - name: {{ salt['pillar.get']('rabbitmq:management:user') }}
    - password: {{ salt['pillar.get']('rabbitmq:management:password', None)|default(salt['password.pillar']('rabbitmq:management:password'), boolean=True) }}
    - force: True
    - require:
      - service: rabbitmq-server
    - tags:
      - administrator

rabbitmq_delete_guest:
  rabbitmq_user:
    - absent
    - runas: root
    - name: guest
    - require:
      - service: rabbitmq-server
{% endif %} {#- END OF states only for MASTER NODE #}

{% if grains['id'] != master_id %}
join_rabbitmq_cluster:
  rabbitmq_cluster:
    - joined
    - runas: root
    - host: {{ master_id }}
    - user: rabbit
    - require:
      - rabbitmq_plugin: rabbitmq-server
      - service: rabbitmq-server
{% endif %}

{% for node in nodes -%}
    {% if node != grains['id'] -%}
host_{{ node }}:
  host:
    - present
    - name: {{ node }}
    - ip: {{ nodes[node]['private'] }}
    {% endif %}
{% endfor %}

/etc/nginx/conf.d/rabbitmq.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: www-data
    - mode: 400
    - source: salt://nginx/proxy.jinja2
    - require:
      - pkg: nginx
    - context:
        destination: http://127.0.0.1:15672
        ssl: {{ salt['pillar.get']('rabbitmq:ssl', False) }}
        ssl_redirect: {{ salt['pillar.get']('rabbitmq:ssl_redirect', True) }}
        hostnames: {{ salt['pillar.get']('rabbitmq:hostnames') }}
    - watch_in:
      - service: nginx

{% if salt['pillar.get']('rabbitmq:ssl', False) %}
extend:
  nginx:
    service:
      - watch:
        - cmd: ssl_cert_and_key_for_{{ salt['pillar.get']('rabbitmq:ssl', False) }}
{% endif %}
