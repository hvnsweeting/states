{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - python.common

python:
  pkg:
    - latest
    - name: python{{ grains['pythonversion'][0] }}.{{ grains['pythonversion'][1] }}
    - require:
      - cmd: apt_sources
