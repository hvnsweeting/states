{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - uwsgi
  - python.3.dev

{%- set version = '1.9.17.1' -%}
{%- set extracted_dir = '/usr/local/uwsgi-{0}'.format(version) %}
uwsgi_python3:
  cmd:
    - run
    - name: python3 uwsgiconfig.py --plugin plugins/python custom python34
    - unless: test -f {{ extracted_dir }}/python34_plugin.so
    - cwd: {{ extracted_dir }}
    - stateful: false
    - watch:
      - pkg: xml-dev
      - archive: uwsgi_build
      - file: uwsgi_build
      - pkg: python-dev
      - file: uwsgi_patch_carbon_name_order
      - cmd: uwsgi_build
    - require:
      - pkg: python3-dev
    - watch_in:
      - service: uwsgi
