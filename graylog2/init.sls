{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if not files_archive %}
  {%- set files_archive = "http://archive.robotinfra.com" %}
{%- endif %}

include:
  - apt

{%- set version = '1.3.4' %}
graylog:
  pkgrepo:
    - managed
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/graylog/{{ version }} {{ grains['oscodename'] }} 1.3
    - key_url: salt://graylog2/pubkey.gpg
    - file: /etc/apt/sources.list.d/graylog.list
    - clean_file: True
    - require:
      - cmd: apt_sources
