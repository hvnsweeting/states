{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

apt-key del 0E27C0A6:
  cmd:
    - run
    - onlyif: apt-key list | grep -q 0E27C0A6

{%- set version = '0.17.5-1' %}
{%- for i in ('list', 'list.save') %}
salt_absent_old_apt_salt_{{ i }}:
  file:
    - absent
    - name: /etc/apt/sources.list.d/saltstack-salt-{{ grains['oscodename'] }}.{{ i }}
{%- endfor %}

salt:
  pkgrepo:
    - absent
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/salt/{{ version }} {{ grains['oscodename'] }} main
{%- else %}
    - name: deb http://archive.robotinfra.com/mirror/salt/{{ version }} {{ grains['oscodename'] }} main
{%- endif %}
    - file: /etc/apt/sources.list.d/saltstack-salt.list
  file:
    - absent
    - name: /etc/apt/sources.list.d/saltstack-salt.list
    - require:
      - pkgrepo: salt
