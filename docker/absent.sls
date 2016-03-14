{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "upstart/absent.sls" import upstart_absent with context -%}
{{ upstart_absent('docker') }}

docker_absent:
  file:
    - absent
    - name: /etc/apt/sources.list.d/docker.list
  pkg:
    - purged
    - pkgs:
      - docker-engine
      - linux-image-extra-{{ grains['kernelrelease'] }}
    - require:
      - file: docker_absent
    - require_in:
      - file: docker
  user:
    - absent
    - name: docker
    - force: True
    - require:
      - pkg: docker_absent
  group:
    - absent
    - name: docker
    - force: True
    - require:
      - pkg: docker_absent

/var/lib/docker:
  file:
    - absent
    - name: /var/lib/docker
    - require:
      - pkg: docker_absent

/etc/docker:
  file:
    - absent
    - require:
      - pkg: docker_absent
