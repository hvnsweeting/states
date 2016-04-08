{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'macros.jinja2' import manage_pid with context %}
{%- set ssl = salt['pillar.get']('elasticsearch:ssl', False) %}
include:
  - apt
  - bash
  - cron
  - hostname
  - java.7
  - salt.minion.deps
  - rsyslog
{% if ssl %}
  - nginx
  - ssl
{% endif %}
{%- set version = '1.7.5' %}

/etc/default/elasticsearch:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://elasticsearch/default.jinja2
    - require:
      - pkg: elasticsearch

/etc/elasticsearch/logging.yml:
  file:
    - managed
    - template: jinja
    - user: root
    - group: elasticsearch
    - mode: 440
    - source: salt://elasticsearch/logging.jinja2
    - require:
      - pkg: elasticsearch
      - service: rsyslog

/var/log/elasticsearch:
  file:
    - absent
    - require:
      - service: elasticsearch

/etc/cron.daily/elasticsearch-cleanup:
  file:
    - absent
    - require:
      - service: elasticsearch

{%- call manage_pid('/var/run/elasticsearch.pid', 'elasticsearch', 'elasticsearch', 'elasticsearch') %}
- pkg: elasticsearch
{%- endcall %}

elasticsearch:
  pkg:
    - installed
    - sources:
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
        - elasticsearch: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/elasticsearch-{{ version }}.deb
{%- else %}
        - elasticsearch: http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-{{ version }}.deb
{%- endif %}
    - require:
      - host: hostname
      - pkg: jre-7
{%- set aws = salt['pillar.get']('elasticsearch:aws', False) %}
{% if aws %}
  elasticsearch_plugins:
    - installed
    - name: cloud-aws
    - url: elasticsearch/elasticsearch-cloud-aws/{{ salt['pillar.get']('elasticsearch:elasticsearch-cloud-aws_version') }}
    - require:
      - pkg: elasticsearch
{% endif %}
  user:
    - present
    - shell: /bin/false
    - require:
      - pkg: elasticsearch
  file:
    - managed
    - name: /etc/elasticsearch/elasticsearch.yml
    - template: jinja
    - user: root
    - group: elasticsearch
    - mode: 440
    - source: salt://elasticsearch/config.jinja2
    - context:
        master: 'true'
        data: 'true'
        origin_state: elasticsearch
    - require:
      - pkg: elasticsearch
  service:
    - running
    - enable: True
    - order: 50
    - watch:
      - file: /etc/default/elasticsearch
      - file: /etc/elasticsearch/logging.yml
      - file: elasticsearch
      - pkg: elasticsearch
      - pkg: jre-7
      - file: jre-7
{%- if grains['cpuarch'] == 'i686' %}
      - file: jre-7-i386
{%- endif -%}
{%- if aws %}
      - elasticsearch_plugins: elasticsearch
{%- endif %}
      - user: elasticsearch
  process:
    - wait
    - name: '-Delasticsearch'
    - timeout: 10
    - require:
      - pkg: elasticsearch
      - pkg: salt_minion_deps
      - service: elasticsearch

{%- if salt['pkg.version']('elasticsearch') not in ('', version) %}
elasticsearch_old_version:
  pkg:
    - removed
    - name: elasticsearch
    - require_in:
      - pkg: elasticsearch
{%- endif %}

{% if ssl %}
  {%- set username = salt['pillar.get']('elasticsearch:username', False) %}
  {%- set password = salt['pillar.get']('elasticsearch:password', False) %}
/etc/nginx/conf.d/elasticsearch.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: www-data
    - mode: 400
    - require:
      - pkg: nginx
  {%- if username and password %}
      - file: /etc/elasticsearch/nginx_basic_auth
  {%- endif %}
    - show_diff: False
    - watch_in:
      - service: nginx
    - source: salt://nginx/proxy.jinja2
    - context:
        destination: http://127.0.0.1:9200
        http_port: False
        ssl: {{ ssl }}
        hostnames: {{ salt['pillar.get']('elasticsearch:hostnames') }}
        allowed:
  {% for ip_address in grains['ipv4'] %}
          - {{ ip_address }}/32
  {% endfor %}
  {% for allowed in salt['pillar.get']('elasticsearch:https_allowed', []) %}
          - {{ allowed }}
  {% endfor %}
  {%- if username and password %}
        auth_file: /etc/elasticsearch/nginx_basic_auth

/etc/elasticsearch/nginx_basic_auth:
  file:
    - managed
    - user: root
    - group: www-data
    - contents: {{ username }}:{{ salt['password.encrypt_shadow'](password|string, salt_key=salt['password.generate']('elasticsearch_nginx_basic_auth')) }}
    - mode: 440
    - require:
      - pkg: nginx
      - pkg: elasticsearch
    - watch_in:
      - service: nginx
  {%- else %}

/etc/elasticsearch/nginx_basic_auth:
  file:
    - absent
  {%- endif %}

extend:
  nginx:
    service:
      - watch:
        - cmd: ssl_cert_and_key_for_{{ ssl }}
{%- else %}
/etc/nginx/conf.d/elasticsearch.conf:
  file:
    - absent
{% endif %}
