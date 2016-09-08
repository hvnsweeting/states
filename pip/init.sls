{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - git
  - hostname
  - local
  - mercurial
  - python
  - ssh.client

{% set root_user_home = salt['user.info']('root')['home'] %}

{{ root_user_home }}/.pip:
  file:
    - absent

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
/var/cache/pip:
  file:
    - absent
{%- else %}
/var/cache/pip:
  file:
    - directory
    - user: root
    - group: root
    - mode: 700
{%- endif %}

pip-config:
  file:
    - managed
    - name: /etc/pip.conf
    - template: jinja
    - source: salt://pip/config.jinja2
    - user: root
    - group: root
    - require:
      - file: {{ root_user_home }}/.pip
      - file: /var/cache/pip

distutils-config:
  file:
    - managed
    - name: {{ root_user_home }}/.pydistutils.cfg
    - template: jinja
    - source: salt://pip/distutils.jinja2
    - user: root
    - group: root

python-pip:
  pkg:
    - purged

python-setuptools:
  pkg:
    - installed
    - require:
      - cmd: apt_sources

{{ opts['cachedir'] }}/pip:
  file:
    - directory
    - user: root
    - group: root
    - mode: 550

{%- set version='8.1.1' %}

pip:
  file:
    - directory
    - name: /usr/local/lib/python{{ grains['pythonversion'][0] }}.{{ grains['pythonversion'][1] }}/dist-packages
    - makedirs: True
  archive:
    - extracted
    - name: {{ opts['cachedir'] }}/pip
{%- if files_archive %}
    - source: {{ files_archive }}/pip/pip-{{ version }}.tar.gz
{%- else %}
    - source: https://pypi.python.org/packages/source/p/pip/pip-{{ version }}.tar.gz
{%- endif %}
    - source_hash: md5=6b86f11841e89c8241d689956ba99ed7
    - archive_format: tar
    - tar_options: z
    - if_missing: {{ opts['cachedir'] }}/pip/pip-{{ version }}
    - require:
      - host: hostname
      - file: /usr/local
      - file: {{ opts['cachedir'] }}/pip
  module:
{%- if not salt['file.file_exists']('/usr/local/bin/pip') -%}
    {#- force module to run if pip isn't installed yet #}
    - run
{%- else %}
    - wait
    - watch:
      - archive: pip
{%- endif %}
    - name: cmd.run
    - cmd: /usr/bin/python setup.py install
    - cwd: {{ opts['cachedir'] }}/pip/pip-{{ version }}
    - require:
      - pkg: python-pip
      - file: pip-config
      - file: distutils-config
      - pkg: python
      - pkg: python-setuptools
      - file: pip
{%- if not salt['file.file_exists']('/usr/local/bin/pip') %}
      - archive: pip
{%- endif %}
