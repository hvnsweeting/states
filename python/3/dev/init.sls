{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - build
  - python.3

python3-dev:
  pkg:
    - latest
    - require:
      - pkg: build
      - cmd: apt_sources
      - pkg: python
