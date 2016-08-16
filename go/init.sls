{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - git
  - build
  - mercurial
  - local

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- set version = '1.7' %}

go:
  archive:
    - extracted
    - name: /usr/local
{%- if files_archive %}
    - source: {{ files_archive|replace('https://', 'http://') }}/mirror/go{{ version }}.{{ grains['kernel'] | lower }}-{{ grains['osarch'] }}.tar.gz
{%- else %}
    - source: https://storage.googleapis.com/golang/go{{ version }}.{{ grains['kernel'] | lower }}-{{ grains['osarch'] }}.tar.gz
{%- endif %}
    - source_hash: sha256=702ad90f705365227e902b42d91dd1a40e48ca7f67a2f4b2fd052aaa4295cd95
    - source_hash_update: true
    - tar_options: z
    - if_missing: /usr/local/go
    - archive_format: tar
    - require:
      - file: /usr/local

{%- for f in ('go', 'gofmt', 'godoc') %}
go_{{ f }}:
  file:
    - symlink
    - name: /usr/local/bin/{{ f }}
    - target: /usr/local/go/bin/{{ f }}
    - require:
      - archive: go
    - require_in:
      - cmd: go_state_api
{%- endfor %}

gopath:
  file:
    - directory
    - name: /var/lib/go

gopath_env:
  file:
    - append
    - name: /etc/environment
    - text: |
        export GOPATH="/var/lib/go"
    - require:
      - file: gopath

go_state_api: {# API #}
  cmd:
    - wait
    - name: echo "Finished go SLS"
    - require:
      - file: gopath_env
      - pkg: git
      - pkg: mercurial
      - pkg: build
