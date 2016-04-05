{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set default_modules = ['nf_conntrack'] if grains['virtual'] != 'openvzve' else [] %}

{%- set modules = salt['pillar.get']('kernel_modules', [])|default(default_modules, boolean=True) %}
{%- for module in modules %}
  {%- if module not in modules[loop.index:] %}
kernel_module_{{ module }}:
  kmod:
    - present
    - name: {{ module }}
    - persist: True
    - require:
      - cmd: kernel_modules
    - require_in:
      - file: kernel_modules
  {%- endif %}
{%- endfor %}

{#- API #}
kernel_modules:
  {#-
  Some kernel modules require other packages must be installed.
  This acts as an API to ensure that: after required packages are installed,
  run this state, then load kernel modules.
  #}
  cmd:
    - run
    - name: echo "This state run before all kernel modules are loaded, help ordering states."
  file:
    - managed
    - name: /etc/modules
    - user: root
    - group: root
    - mode: 644
    - replace: False
