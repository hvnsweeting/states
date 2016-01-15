{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

go:
  pkg:
    - purged
    - pkgs:
      - golang-go
      - golang-src
      - golang-go-linux-{{ grains['osarch'] }}
  cmd:
    - run
    - name: 'apt-key del 742A38EE'
    - onlyif: apt-key list | grep -q 742A38EE
  pkgrepo:
    - absent
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/go/1.4.1 {{ grains['oscodename'] }} main
{%- else %}
    - ppa: evarlast/golang1.4
{%- endif %}
  file:
    - absent
    - name: /etc/apt/sources.list.d/go.list
    - require:
      - pkgrepo: go
