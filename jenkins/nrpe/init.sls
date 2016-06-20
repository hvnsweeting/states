{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'nrpe/passive.jinja2' import passive_check with context %}
include:
  - apt.nrpe
  - cron.nrpe
  - nginx.nrpe
  - pysc.nrpe
  - ssh.client.nrpe
{%- if salt['pillar.get']('jenkins:job_cleaner', False) %}
  - requests.nrpe
{%- endif %}
{% if salt['pillar.get']('jenkins:ssl', False) %}
  - ssl.nrpe
{%- endif %}

/usr/lib/nagios/plugins/check_jenkins_slaves.py:
  file:
    - managed
    - source: salt://jenkins/nrpe/check_slaves.py
    - user: root
    - group: nagios
    - mode: 550
    - require:
      - module: nrpe-virtualenv
      - pkg: nagios-nrpe-server

{{ passive_check('jenkins', check_ssl_score=True) }}
