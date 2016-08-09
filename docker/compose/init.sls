{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
  {%- if not files_archive %}
    {%- set files_archive = "http://archive.robotinfra.com" %}
  {%- endif %}
include:
  - apt
  - local
  - pip
  - virtualenv

docker_compose_virtualenv:
  virtualenv:
    - manage
    - name: /usr/local/docker-compose
    - system_site_packages: False
    - require:
      - module: virtualenv
      - file: /usr/local
  pip:
    - installed
    - bin_env: /usr/local/docker-compose
    - name: docker-compose
    - require:
      - module: pip
      - virtualenv: docker_compose_virtualenv
  file:
    - symlink
    - name: /usr/local/bin/docker-compose
    - target: /usr/local/docker-compose/bin/docker-compose
    - require:
      - pip: docker_compose_virtualenv
