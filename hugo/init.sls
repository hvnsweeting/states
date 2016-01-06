{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set filename = 'hugo_0.14_' ~ grains['osarch'] ~ '.deb' %}
{%- set files_archive = salt['pillar.get']('files_archive', False) %}

include:
  - apt

hugo:
  pkg:
    - installed
    - sources:
{%- if files_archive %}
      - hugo: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/{{ filename }}
{%- else %}
      - hugo: https://github.com/spf13/hugo/releases/download/v0.14/{{ filename }}
{%- endif %}
    - require:
      - cmd: apt_sources
