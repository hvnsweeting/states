{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - local
  - ssh.client

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- set version = '1.6' %}

go:
  archive:
    - extracted
    - name: /usr/local
{%- if files_archive %}
    - source: {{ files_archive|replace('https://', 'http://') }}/mirror/go/go{{ version }}.{{ grains['kernel'] | lower }}-{{ grains['osarch'] }}.tar.gz
{%- else %}
    - source: https://storage.googleapis.com/golang/go{{ version }}.{{ grains['kernel'] | lower }}-{{ grains['osarch'] }}.tar.gz
{%- endif %}
    - source_hash: sha256=5470eac05d273c74ff8bac7bef5bad0b5abbd1c4052efbdbc8db45332e836b0b
    - tar_options: z
    - if_missing: /usr/local/go
    - archive_format: tar
    - require:
      - file: /usr/local
