{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set files_archive = salt['pillar.get']('files_archive', False) %}

mingw:
  pkg:
    - purged
    - names:
      - mingw32-x-binutils
      - mingw32-x-gcc
      - mingw64-x-binutils
      - mingw64-x-gcc
  pkgrepo:
    - absent
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/mingw {{ grains['oscodename'] }} main
    - key_url: salt://mingw/key.gpg
{%- else %}
    - ppa: tobydox/mingw-x-trusty
{%- endif %}
  file:
    - absent
    - name: /etc/apt/sources.list.d/mingw-x-trusty.list
    - require:
      - pkgrepo: mingw
