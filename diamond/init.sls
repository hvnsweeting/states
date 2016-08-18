{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'upstart/rsyslog.jinja2' import manage_upstart_log with context -%}
include:
{% if salt['pillar.get']('shinken_pollers', []) %}
  - diamond.nrpe
{% endif %}
  - git
  - kernel.modules
  - local
  - python.dev
  - rsyslog
  - rsyslog.diamond
  - virtualenv

/etc/diamond:
  file:
    - directory
    - user: root
    - group: root
    - mode: 550

/etc/diamond/collectors:
  file:
    - directory
    - user: root
    - group: root
    - mode: 550
    - require:
      - file: /etc/diamond

/usr/local/diamond/salt-requirements.txt:
  file:
    - absent

diamond_requirements:
  file:
    - managed
    - name: {{ opts['cachedir'] }}/pip/diamond
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://diamond/requirements.jinja2
    - require:
      - virtualenv: diamond

diamond.conf:
  file:
    - managed
    - name: /etc/diamond/diamond.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://diamond/config.jinja2
    - require:
      - file: /etc/diamond

diamond:
  virtualenv:
    - manage
    - name: /usr/local/diamond
    - require:
      - module: virtualenv
      - file: /usr/local
  module:
    - wait
    - name: pip.install
    - upgrade: True
    - bin_env: /usr/local/diamond
    - requirements: {{ opts['cachedir'] }}/pip/diamond
    - require:
      - pkg: git
    - watch:
      - pkg: python-dev
      - file: diamond_requirements
      - virtualenv: diamond
  file:
    - managed
    - name: /etc/init/diamond.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://diamond/upstart.jinja2
    - require:
      - module: diamond
  service:
    {#- does not use PID, no need to manage #}
    - running
    - enable: True
    - order: 50
    - require:
      - service: rsyslog
      {#- requires specific pillar key, look at diamond/doc/pillar.rst #}
      - kmod: kernel_module_nf_conntrack
    - watch:
      - virtualenv: diamond
      - file: diamond.conf
      - file: diamond
      - module: diamond
      - cmd: diamond
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
  cmd:
    - wait
    - name: find /usr/local/diamond -name '*.pyc' -delete
    - stateful: False
    - watch:
      - module: diamond

/usr/local/diamond/share/diamond/user_scripts:
  file:
    - directory
    - user: root
    - group: root
    - mode: 750
    - require:
      - module: diamond
    - require_in:
      - service: diamond

{{ manage_upstart_log('diamond') }}

/etc/diamond/collectors/ProcessResourcesCollector.conf:
  file:
    - managed
    - template: jinja
    - source: salt://diamond/ProcessResourcesCollector.jinja2
    - user: root
    - group: root
    - mode: 440
    - require:
      - file: /etc/diamond/collectors

/usr/local/diamond/lib/python2.7/site-packages/diamond/handler/influxdbHandler.py:
  file:
    - managed
    - source: salt://diamond/influxdbHandler.py
    - user: root
    - group: root
    - mode: 440
    - require:
      - module: diamond
    - watch_in:
      - service: diamond
