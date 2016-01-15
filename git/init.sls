{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - ssh.client

git:
  pkgrepo:
    - managed
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/git {{ grains['oscodename'] }} main
    - key_url: salt://git/key.gpg
{%- else %}
    - ppa: git-core/ppa
{%- endif %}
    - file: /etc/apt/sources.list.d/git-core.list
    - clean_file: True
    - require:
      - pkg: apt_sources
  pkg:
    - latest
{%- if grains['osrelease']|float < 12.04 %}
    - name: git-core
{%- endif %}
    - require:
      - file: openssh-client
      - cmd: apt_sources
      - pkgrepo: git
