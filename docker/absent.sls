{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

docker:
  pkgrepo:
    - absent
    - file: /etc/apt/sources.list.d/docker.list
  pkg:
    - purged
    - pkgs:
      - docker-engine
      - linux-image-extra-{{ grains['kernelrelease'] }}
