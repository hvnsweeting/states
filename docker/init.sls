{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
  {%- if not files_archive %}
    {%- set files_archive = "http://archive.robotinfra.com" %}
  {%- endif %}
include:
  - apt
  - pip


docker_prequisites:
  pkg:
    - latest
    - name: linux-image-extra-{{ grains['kernelrelease'] }}

docker:
  file:
    - absent
    - name: /etc/apt/sources.list.d/docker.list
  pkg:
    - installed
    - sources:
      - docker-engine: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/docker-engine_1.12.0-0~{{ grains['oscodename'] }}_amd64.deb
    - require:
      - cmd: apt_sources
      - file: docker
  pip:
    - installed
    - name: docker-py {# for salt docker modules #}
    - require:
      - module: pip
      - pkg: docker
    - reload_modules: True
  service:
    - running
    - watch:
      - pkg: docker
