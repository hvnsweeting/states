{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - python.common

python3:
  pkg:
    - latest
    - name: python3
    - require:
      - cmd: apt_sources
