{#- Usage of this is governed by a license that can be found in doc/license.rst

For setup a postgresql cluster, create overstate.sls at top level of states, with
content like below::

  master:
    match: 'pgmaster'
    sls:
      - postgresql.server.master

  standby:
    match: '*standby'
    sls:
      - postgresql.server.standby
    require:
      - master

See document for more:
https://salt.readthedocs.org/en/latest/ref/states/overstate.html

match: to match the minion-id that will run state specified in sls
sls: list of states to run on matched minions
require: require other "over" state run before it. In above example,
  sls postgresql.server.master will be ran on minion that have id 'pgmaster'
  then sls postgresql.server.standby will run on all minion that match
  '*standby'.
Master servers need to setup before standby servers to provide basebackup for
standby servers.
-#}

{% from "postgresql/map.jinja2" import postgresql with context %}
{% set version = postgresql.version %}

include:
  - postgresql.server

replication_agent:
  postgres_user:
    - present
    - name: {{ salt['pillar.get']('postgresql:replication:username', 'replication_agent') }}
    - user: postgres
    - superuser: True
    - require:
      - service: postgresql

extend:
  /etc/postgresql/{{ version }}/main/pg_hba.conf:
    file:
      - context:
          master: True
  postgresql:
    file:
      - context:
          version: {{ version }}
          role: master
