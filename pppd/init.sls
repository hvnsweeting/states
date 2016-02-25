{#- Usage of this is governed by a license that can be found in doc/license.rst -#}
{%- set instances = salt['pillar.get']('pppd:instances', {}) -%}

include:
  - apt

ppp:
  pkg:
    - installed
    - require:
      - cmd: apt_sources

{%- set managed_files = [] %}
{%- for instance in instances %}
    {%- do managed_files.append('/etc/ppp/' + instance + '-options') %}
{%- endfor %}
{%- for file in salt['file.find']('/etc/ppp', name='*-options', type='f') %}
  {%- if file not in managed_files %}
{{ file }}:
  file:
    - absent
  {%- endif %}
{%- endfor %}

{%- for server_name in instances %}
ppp-options-{{ server_name }}:
  file:
    - managed
    - name: /etc/ppp/{{ server_name }}-options
    - source: salt://pppd/options.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: ppp
    - defaults:
        server_name: {{ server_name }}
{%- endfor %}
