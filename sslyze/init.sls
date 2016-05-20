{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{% set version = "0.9" %}
include:
  - cron
  - hostname
  - local
  - nrpe
  - salt.minion.deps
  - virtualenv

{%- if grains['osarch'] == 'amd64' -%}
    {%- set bits = "64" -%}
    {%- set sum = "1b5a235f97db11cc2f72ccb499d861f0" -%}
{%- else -%}
    {%- set bits = "32" -%}
    {%- set sum = "4471cfc348b4d1777fc39dc9200f6cc5" -%}
{%- endif %}

sslyze:
  archive:
    - extracted
    - name: /usr/local/src
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - source: {{ files_archive }}/mirror/sslyze-{{ version|replace(".", "_") }}-linux{{ bits }}.zip
{%- else %}
    {#- source: https://github.com/iSECPartners/sslyze #}
    - source: http://archive.robotinfra.com/mirror/sslyze-{{ version|replace(".", "_") }}-linux{{ bits }}.zip
{%- endif %}
    - source_hash: md5={{ sum }}
    - if_missing: /usr/local/src/sslyze-{{ version|replace(".", "_") }}-linux{{ bits }}
    - archive_format: zip
    - require:
      - file: /usr/local/src
      - pkg: salt_minion_deps
  cmd:
    - wait
{%- if grains['osarch'] == 'amd64' %}
    - cwd: /usr/local/src/sslyze-{{ version|replace(".", "_") }}-linux64
{%- else %}
    - cwd: /usr/local/src/sslyze-{{ version|replace(".", "_") }}-linux32
{%- endif %}
    - name: /usr/local/nagios/bin/python setup.py install
    - watch:
      - archive: sslyze
      - virtualenv: nrpe-virtualenv

{%- if salt['pillar.get']('__test__', False) -%}
    {%- for name in salt['pillar.get']('ssl:certs', {}) -%}
        {%- for trust_store in ('apple', 'java', 'microsoft', 'mozilla') %}
sslyze_{{ name }}_{{ trust_store }}:
  file:
    - append
    - name: /usr/local/src/sslyze-{{ version|replace(".", "_") }}-linux{{ bits }}/plugins/data/trust_stores/{{ trust_store }}.pem
    - text: |
        {{ salt['pillar.get']('ssl:certs:' + name + ':server_crt') | indent(8) }}
    - require:
      - archive: sslyze
    - require_in:
      - cmd: sslyze
        {%- endfor -%}
    {%- endfor -%}
{%- endif %}

check_ssl_configuration.py:
  file:
    - managed
    - name: /usr/lib/nagios/plugins/check_ssl_configuration.py
    - source: salt://sslyze/check_ssl_configuration.py
    - user: root
    - group: nagios
    - mode: 550
    - require:
      - host: hostname
      - pkg: nagios-nrpe-server
      - module: nrpe-virtualenv
      - cmd: sslyze
      - pkg: salt_minion_deps
{#- consumers of sslyze check use cron, make them only require sslyze check script #}
      - pkg: cron
    - require_in:
      - service: nagios-nrpe-server
      - service: nsca_passive
