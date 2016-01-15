{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "os.jinja2" import os with context %}

include:
  - apt

{%- set files_archive = salt['pillar.get']('files_archive', False) %}

libjs-underscore:
{%- if os.is_precise %}
  {%- set version = '1.4.2-1chl1~precise1' %}
  pkgrepo:
    - managed
  {%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/underscore/1.4.2-1 {{ grains['oscodename'] }} main
    - key_url: salt://underscore/key.gpg
  {%- else %}
    - ppa: chris-lea/libjs-underscore
  {%- endif %}
    - file: /etc/apt/sources.list.d/chris-lea-libjs-underscore-{{ grains['oscodename'] }}.list
    - clean_file: True
    - require:
      - cmd: apt_sources
    - require_in:
      - pkg: libjs-underscore
{%- endif %}
  pkg:
    - installed
    - require:
      - cmd: apt_sources
