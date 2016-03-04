{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{% from 'upstart/rsyslog.jinja2' import manage_upstart_log with context %}
include:
  - git
  - local
  - python.dev
  - rsyslog
  - salt.minion.deps
  - web
  - xml

{#-
{%- for previous_version in () %}
/usr/local/uwsgi-{{ previous_version }}:
  file:
    - absent
{%- endfor %}
#}

{%- set version = '1.9.17.1' -%}
{%- set extracted_dir = '/usr/local/uwsgi-{0}'.format(version) %}

/etc/uwsgi.yml:
  file:
    - managed
    - template: jinja
    - source: salt://uwsgi/config.jinja2
    - mode: 440

uwsgi_patch_carbon_name_order:
  pkg:
    - installed
    - name: patch
{#- https://github.com/unbit/uwsgi/issues/534 #}
  file:
    - patch
    - name: {{ extracted_dir }}/plugins/carbon/carbon.c
    - source: salt://uwsgi/carbon.patch
    - hash: md5=1f96187b79550be801a9ab1397cb66ca
    - require:
      - archive: uwsgi_build
      - pkg: uwsgi_patch_carbon_name_order

uwsgi_build:
  archive:
    - extracted
    - name: /usr/local
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - source: {{ files_archive }}/mirror/uwsgi-{{ version }}.tar.gz
{%- else %}
    - source: http://projects.unbit.it/downloads/uwsgi-{{ version }}.tar.gz
{%- endif %}
    - source_hash: md5=501f29ad4538193c0ef585b4cef46bcf
    - archive_format: tar
    - tar_options: z
    - if_missing: {{ extracted_dir }}
    - require:
      - file: /usr/local
  file:
    - managed
    - name: {{ extracted_dir }}/buildconf/custom.ini
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://uwsgi/buildconf.jinja2
    - require:
      - archive: uwsgi_build
  cmd:
    - wait
    - name: python uwsgiconfig.py --clean; python uwsgiconfig.py --build custom
    - cwd: {{ extracted_dir }}
    - stateful: false
    - watch:
      - pkg: xml-dev
      - archive: uwsgi_build
      - file: uwsgi_build
      - pkg: python-dev
      - file: uwsgi_patch_carbon_name_order

uwsgi_sockets:
  file:
    - directory
    - name: /var/lib/uwsgi
    - user: www-data
    - group: www-data
    - mode: 770
    - require:
      - user: web
      - cmd: uwsgi_build
      - archive: uwsgi_build
      - file: uwsgi_build

/etc/uwsgi:
  file:
    - directory
    - user: www-data
    - group: www-data
    - mode: 550
    - require:
      - user: web

{#-
  uWSGI emperor
#}
uwsgi:
  file:
    - managed
    - name: /etc/init/uwsgi.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - context:
        extracted_dir: {{ extracted_dir }}
    - source: salt://uwsgi/upstart.jinja2
  cmd:
    - wait
    - name: strip {{ extracted_dir }}/uwsgi
    - stateful: false
    - watch:
      - archive: uwsgi_build
      - file: uwsgi_build
      - cmd: uwsgi_build
  service:
    - running
    - name: uwsgi
    - enable: True
    - order: 50
    - require:
      - file: /etc/uwsgi
      - file: uwsgi_sockets
      - service: rsyslog
      - pkg: salt_minion_deps
    - watch:
      - cmd: uwsgi
      - file: uwsgi
      - file: /etc/uwsgi.yml
      - user: web
{#- does not use PID, no need to manage #}

{{ manage_upstart_log('uwsgi') }}
