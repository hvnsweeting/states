{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - ssh.client

go:
  pkgrepo:
    - managed
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/go/1.4.1 {{ grains['oscodename'] }} main
    - key_url: salt://go/key.gpg
{%- else %}
    - ppa: evarlast/golang1.4
{%- endif %}
    - file: /etc/apt/sources.list.d/go.list
    - clean_file: True
    - require:
      - pkg: apt_sources
  pkg:
    - latest
    - name: golang-go
    - require:
      - pkgrepo: go
