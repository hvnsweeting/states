{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

git:
  pkg:
    - purged
  cmd:
    - run
    - name: 'apt-key del E1DF1F24'
    - onlyif: apt-key list | grep -q E1DF1F24
  pkgrepo:
    - absent
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/git {{ grains['oscodename'] }} main
{%- else %}
    - ppa: git-core/ppa
{%- endif %}
  file:
    - absent
    - name: /etc/apt/sources.list.d/git-core.list
    - require:
      - pkgrepo: git
