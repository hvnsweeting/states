{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - git
  - mercurial
  - pip

python-virtualenv:
  pkg:
    - purged

virtualenv:
  file:
    - managed
    - name: {{ opts['cachedir'] }}/pip/virtualenv
    - source: salt://virtualenv/requirements.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - require:
      - module: pip
  module:
{%- if not salt['file.file_exists']('/usr/local/bin/virtualenv') -%}
    {#- force module to run if virtualenv isn't installed yet #}
    - run
{%- else %}
    - wait
    - watch:
      - file: virtualenv
{%- endif %}
    - name: pip.install
    - requirements: {{ opts['cachedir'] }}/pip/virtualenv
    - require:
      - pkg: git
      - pkg: mercurial
{%- if not salt['file.file_exists']('/usr/local/bin/virtualenv') %}
      - file: virtualenv
{%- endif -%}
