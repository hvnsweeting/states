{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - git
  - build
  - mercurial
  - local

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- set version = '1.6.2' %}

go:
  archive:
    - extracted
    - name: /usr/local
{%- if files_archive %}
    - source: {{ files_archive|replace('https://', 'http://') }}/mirror/go/{{ version }}/go{{ version }}.{{ grains['kernel'] | lower }}-{{ grains['osarch'] }}.tar.gz
{%- else %}
    - source: https://storage.googleapis.com/golang/go{{ version }}.{{ grains['kernel'] | lower }}-{{ grains['osarch'] }}.tar.gz
{%- endif %}
    - source_hash: sha256=e40c36ae71756198478624ed1bb4ce17597b3c19d243f3f0899bb5740d56212a
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
