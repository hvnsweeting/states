{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "os.jinja2" import os with context %}
{%- from "nodejs/map.jinja2" import nodejs with context %}

include:
  - apt

{%- set files_archive = salt['pillar.get']('files_archive', False) %}

nodejs:
{% if nodejs.default_version %}
  pkg:
    - installed
    - require:
      - cmd: apt_sources
  {%- if os.is_trusty %}
    - pkgs:
      - nodejs-legacy
      - npm
  {%- elif os.is_precise %}
    {%- set filename = "nodejs_" +  nodejs.version  + "-1chl1~" +  grains['oscodename']  + "1_" +  grains['osarch']  + ".deb" %}
    - sources:
    {%- if files_archive %}
      - nodejs: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/{{ filename }}
    {%- else %}
      {#- source: ppa:chris-lea/node.js #}
      - nodejs: http://archive.robotinfra.com/mirror/{{ filename }}
    {%- endif %}

nodejs_deps:
  pkg:
    - installed
    - pkgs:
      - rlwrap
    - require_in:
      - pkg: nodejs
  {%- endif %}
{%- else %} {#- nodejs 4.x official repository #}
  pkgrepo:
    - managed
    - name: {{ nodejs.repo }}
    - key_url: salt://nodejs/key.gpg
    - file: /etc/apt/sources.list.d/nodejs.list
    - clean_file: True
    - require:
      - pkg: apt_sources
  pkg:
    - latest
    - require:
      - pkgrepo: nodejs
{%- endif %}
