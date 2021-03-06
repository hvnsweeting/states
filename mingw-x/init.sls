{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt

{%- set files_archive = salt['pillar.get']('files_archive', False) %}

mingw:
  pkgrepo:
    - managed
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/mingw {{ grains['oscodename'] }} main
    - key_url: salt://mingw-x/key.gpg
{%- else %}
    - ppa: tobydox/mingw-x-trusty
{%- endif %}
    - file: /etc/apt/sources.list.d/mingw-x-trusty.list
    - clean_file: True
    - require:
      - cmd: apt_sources
  pkg:
    - installed
    - names:
      - mingw32-x-binutils
      - mingw32-x-gcc
      - mingw64-x-binutils
      - mingw64-x-gcc
    - require:
      - pkgrepo: mingw
