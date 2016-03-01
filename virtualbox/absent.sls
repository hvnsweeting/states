{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- set major_version = '5.0' %}
{%- set full_version = major_version ~ '.14' %}

virtualbox:
  service:
    - dead
    - enable: False
  module:
    - run
    - name: pkg.unhold
    - m_name: virtualbox-{{ major_version }}
    - require:
      - service: virtualbox
  pkg:
    - purged
    - name: virtualbox-{{ major_version }}
    - require:
      - module: virtualbox
  group:
    - absent
    - name: vboxusers
    - require:
      - pkg: virtualbox
  pkgrepo:
    - absent
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/virtualbox/{{ full_version }} {{ grains['oscodename'] }} contrib
{%- else %}
    - name: deb http://download.virtualbox.org/virtualbox/debian {{ grains['oscodename'] }} contrib
{%- endif %}
    - require:
      - pkg: virtualbox
  file:
    - absent
    - names:
      - /etc/apt/sources.list.d/virtualbox.list
      - /etc/init.d/virtualbox
      - /usr/lib/virtualbox
      - /var/log/vbox-install.log
    - require:
      - pkgrepo: virtualbox
