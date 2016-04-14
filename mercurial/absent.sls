{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

mercurial:
  pkg:
    - purged
  file:
    - absent
    - name: {{ opts['cachedir'] }}/pip/mercurial
{%- if salt['cmd.has_exec']('pip') %}
  pip:
    - removed
    - order: 1
{%- endif %}
