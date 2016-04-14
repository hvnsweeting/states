{#- Usage of this is governed by a license that can be found in doc/license.rst -#}
include:
  - apt

mercurial:
  pkg:
    - installed
    - require:
      - cmd: apt_sources
  file:
    - absent
    - name: {{ opts['cachedir'] }}/pip/mercurial
    - require:
      - pkg: mercurial
{% if salt['cmd.has_exec']('pip') %}
  pip:
    - removed
    - name: mercurial
    - watch:
      - file: mercurial
{%- endif %}
