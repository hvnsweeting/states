{#- Usage of this is governed by a license that can be found in doc/license.rst

Install ruby version 2.1
source: https://launchpad.net/~brightbox/+archive/ubuntu/ruby-ng
-#}
include:
  - apt
  - local
  - locale
  - ssl

{%- set version = "2.1.7-1bbox1" %}
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- set mirror = files_archive if files_archive else "http://archive.robotinfra.com" %}
{%- set repo = "deb %s/mirror/ruby/%s %s main" % (
  mirror, version, grains['oscodename']) %}

ruby2:
  pkgrepo:
    - managed
    - name: {{ repo }}
    - key_url: salt://ruby/2/key.gpg
    - file: /etc/apt/sources.list.d/ruby-2.list
    - clean_file: True
    - require:
      - cmd: apt_sources
  pkg: {# API #}
    - latest
    - name: ruby2.1
    - require:
      - cmd: ca-certificates
      - cmd: system_locale
      - pkgrepo: ruby2
  gem:
    - installed
    - name: bundler
    - version: "1.10"
    - user: root
    - require:
      - pkg: ruby2
      - file: /usr/local

{%- for package in ("ruby2.1-dev", "rubygems-integration", ) %}
{{ package }}:
  pkg:
    - latest
    - require:
      - pkgrepo: ruby2
    - require_in:
      - pkg: ruby2
{%- endfor %}
