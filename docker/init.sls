{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
  {%- if not files_archive %}
    {%- set files_archive = "http://archive.robotinfra.com" %}
  {%- endif %}
include:
  - apt
  - pip

docker:
  pkgrepo:
    - managed
    {#- source  https://apt.dockerproject.org/repo #}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/docker {{ grains['oscodename'] }} main
    - key_url: salt://docker/key.gpg
    - file: /etc/apt/sources.list.d/docker.list
    - clean_file: True
    - require:
      - pkg: apt_sources
  pkg:
    - installed
    - pkgs:
      - docker-engine
      - linux-image-extra-{{ grains['kernelrelease'] }}
    - require:
      - cmd: apt_sources
      - pkgrepo: docker
  pip:
    - installed
    - name: docker-py
    - require:
      - module: pip
      - pkg: docker
    - reload_modules: True
