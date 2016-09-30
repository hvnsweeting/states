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
    - wait
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
