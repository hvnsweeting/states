{#- Usage of this is governed by a license that can be found in doc/license.rst

Mange pysc pip package, which provide lib support for python scrips in salt common
-#}

include:
  - local
  - pip
  - python.dev
  - yaml

{{ opts['cachedir'] }}/salt-pysc-requirements.txt:
  file:
    - absent

pysc:
  file:
    - managed
    - name: {{ opts['cachedir'] }}/pip/pysc
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://pysc/requirements.jinja2
  module:
{%- if salt['file.file_exists']('/usr/local/lib/python2.7/dist-packages/_yaml.so') %}
    - wait
{%- else %}
{#- always run pip.install to re-install if _yaml.so does not exist,
    this will fix problem on machine that libyaml is installed somehow and
    it did not trigger pip to reinstall pyyaml #}
    - run
    - force_reinstall: True
{%- endif %}
    - name: pip.install
    - upgrade: True
    - requirements: {{ opts['cachedir'] }}/pip/pysc
    - require:
      - module: pip
      - file: python
    - watch:
      - pkg: yaml
      - file: pysc
      - pkg: python-dev

{#- if this file does not exist, pyyaml was installed by pip is lack of
libyaml, then pkg_resources will print warning everywhere imports yaml #}
pip_systemwide_verify_pyyaml_installed_with_libyaml:
  file:
    - exists
    - name: /usr/local/lib/python2.7/dist-packages/_yaml.so
    - require:
      - module: pysc
      - pkg: yaml

{#- argparse is installed by statsd, which is redundant for python2.7 #}
argparse-pypi:
  module:
    - wait
    - name: pip.uninstall
    - pkgs: argparse
    - watch:
      - module: pysc

pysc_log_test:
  file:
    - managed
    - name: /usr/local/bin/log_test.py
    - source: salt://pysc/log_test.py
    - user: root
    - group: root
    - mode: 550
    - require:
      - module: pysc
      - file: /usr/local
