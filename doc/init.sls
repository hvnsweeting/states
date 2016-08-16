{#- Usage of this is governed by a license that can be found in doc/license.rst

Build salt-common (and non-common) documentation in salt minion cache
directory.
This is mainly used as source of data to perform tests on pillars and metrics.

To manually rebuild doc perform the following::

  source /var/cache/salt/minion/doc/bin/activate

And go where the source code is, it might be in:
``/var/cache/salt/minion/files/$YOUR_ENV``

or in ``/root/salt/states``

maybe in ``/media/sf_salt`` somewhere.

And run::

  doc/build.py /var/cache/salt/minion/doc/output
-#}
include:
  - python.dev {# installing reportlab requires GCC #}
  - git
  - locale
  - pip
  - ssh.client
  - virtualenv

{# installs doc requirements on system-wide python env, required for _module/qa.py #}
doc_root:
  module:
    - wait
    - name: pip.install
    - requirements: {{ opts['cachedir'] }}/pip/doc
    - watch:
      - file: doc_root
      - pkg: git
      - pkg: python-dev
    - reload_modules: True
  file:
    - managed
    - name: {{ opts['cachedir'] }}/pip/doc
    - source: salt://doc/requirements.txt
    - user: root
    - group: root
    - mode: 440
    - require:
      - module: pip
      - sls: ssh.client
      - virtualenv: doc

{{ opts['cachedir'] }}/doc/output:
  file:
    - directory
    - require:
      - virtualenv: doc

doc:
  virtualenv:
    - manage
    - name: {{ opts['cachedir'] }}/doc
    - system_site_packages: True
    - require:
      - module: virtualenv
  file:
    - managed
    - name: {{ opts['cachedir'] }}/doc/requirements.txt
    - source: salt://doc/requirements.txt
    - user: root
    - group: root
    - mode: 440
    - require:
      - virtualenv: doc
  module:
    - wait
    - name: pip.install
    - bin_env: {{ opts['cachedir'] }}/doc
    - requirements: {{ opts['cachedir'] }}/doc/requirements.txt
    - require:
      - module: pip
      - sls: ssh.client
      - virtualenv: doc
    - watch:
      - file: doc
  cmd:
    - wait
    - name: {{ opts['cachedir'] }}/doc/bin/python doc/build.py {{ opts['cachedir'] }}/doc/output
    - require:
      - cmd: system_locale
      - module: doc_root
    - watch:
      - virtualenv: doc
      - module: doc
      - file: {{ opts['cachedir'] }}/doc/output
    - env:
      - VIRTUAL_ENV: {{ opts['cachedir'] }}/doc
{#- if in local file client mode, cp.cache_master module is useless, just run
    from the first files_root defined. #}
{%- if opts['file_client'] == 'local' %}
    - cwd: {{ opts['file_roots'][opts['file_roots'].keys()[0]][0] }}
{%- else -%}
    {%- set saltenv = salt['common.saltenv']() %}
    - cwd: {{ opts['cachedir'] }}/files/{{ saltenv }}

doc_sync_files:
  module:
    - wait
    - name: cp.cache_master
    - saltenv: {{ saltenv }}
    - watch:
      - virtualenv: doc
    - watch_in:
      - cmd: doc
{%- endif %}
