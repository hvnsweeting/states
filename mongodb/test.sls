{#-
Use of this source code is governed by a BSD license that can be found
in the doc/license.rst file.

Author: Bruno Clermont <bruno@robotinfra.com>
Maintainer: Van Pham Diep <favadi@robotinfra.com>
-#}
{%- from 'diamond/macro.jinja2' import diamond_process_test with context %}
include:
  - doc
  - mongodb
  - mongodb.backup
  - mongodb.diamond
  - mongodb.nrpe
  - mongodb.pymongo
  - mongodb.repair

mongodb_test_generate_sample_db_for_backup_test:
  cmd:
    - run
    - name: "mongo citest --eval \"db.msg.insert({'name': 'citest'});\""
    - require:
      - sls: mongodb

test:
  monitoring:
    - run_all_checks
    - order: last
  cmd:
    - run
    - name: /usr/local/bin/backup-mongodb-all
    - require:
      - file: /usr/local/bin/backup-mongodb-all
      - cmd: mongodb_test_generate_sample_db_for_backup_test
      - sls: mongodb.backup
    - require:
      - service: mongodb_repair_post
  qa:
    - test_monitor
    - name: mongodb
    - pillar_doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
  diamond:
    - test
    - map:
        ProcessResources:
    {{ diamond_process_test('mongodb') }}
        MongoDB:
          mongo.asserts.regular: True
          mongo.asserts.warning: True
          mongo.asserts.msg: True
          mongo.asserts.user: True
          mongo.backgroundFlushing.flushes: True
          mongo.backgroundFlushing.total_ms: True
          mongo.backgroundFlushing.average_ms: True
          mongo.backgroundFlushing.last_ms: True
          mongo.connections.current: True
          mongo.connections.available: True
          mongo.connections.totalCreated: True
          mongo.cursors.clientCursors_size: True
          mongo.cursors.timedOut: True
          mongo.cursors.totalOpen: True
          mongo.dur.timeMs.dt: True
          mongo.dur.timeMs.prepLogBuffer: True
          mongo.dur.timeMs.remapPrivateView: True
          mongo.dur.timeMs.writeToJournal: True
          mongo.dur.commits: True
          mongo.dur.commitsInWriteLock: True
          mongo.dur.compression: True
          mongo.dur.earlyCommits: True
          mongo.dur.journaledMB: True
          mongo.dur.writeToDataFilesMB: True
          mongo.globalLock.totalTime: True
          mongo.globalLock.lockTime: True
          mongo.globalLock.currentQueue.total: True
          mongo.globalLock.currentQueue.readers: True
          mongo.globalLock.currentQueue.writers: True
          mongo.globalLock.activeClients.total: True
          mongo.globalLock.activeClients.readers: True
          mongo.globalLock.activeClients.writers: True
          mongo.indexCounters.accesses: True
          mongo.indexCounters.hits: True
          mongo.indexCounters.misses: True
          mongo.indexCounters.resets: True
          mongo.indexCounters.missRatio: True
          mongo.mem.bits: True
          mongo.mem.resident: True
          mongo.mem.virtual: True
          mongo.mem.supported: True
          mongo.mem.mapped: True
          mongo.mem.mappedWithJournal: True
          mongo.network.bytesIn: True
          mongo.network.bytesOut: True
          mongo.network.numRequests: True
          mongo.opcounters.insert: True
          mongo.opcounters.query: True
          mongo.opcounters.update: True
          mongo.opcounters.delete: True
          mongo.opcounters.getmore: True
          mongo.opcounters.command: True
          mongo.opcountersRepl.insert: True
          mongo.opcountersRepl.query: True
          mongo.opcountersRepl.update: True
          mongo.opcountersRepl.delete: True
          mongo.opcountersRepl.getmore: True
          mongo.opcountersRepl.command: True
    - require:
      - sls: mongodb
      - sls: mongodb.diamond

{% set doc = {"_id": 1, "name": "somename", "surname": "somesurname"} -%}

test_mongodb_insert:
  cmodule:
    - check_output
    - name: mongodb.insert
    - output:
        - 1
    - objects:
        - {{ doc }}
    - collection: test
    - database: citest
    - host: localhost
    - port: 27017
    - require:
        - cmd: mongodb_test_generate_sample_db_for_backup_test
        - pkg: python-pymongo

test_mongodb_find:
  cmodule:
    - check_output
    - name: mongodb.find
    - output:
        - {{ doc }}
    - query:
        _id: {{ doc._id }}
    - collection: test
    - database: citest
    - host: localhost
    - port: 27017
    - require:
      - cmodule: test_mongodb_insert

test_mongodb_delete:
  cmodule:
    - check_output
    - name: mongodb.remove
    - output: 1 objects removed
    - query:
        _id: {{ doc._id }}
    - collection: test
    - database: citest
    - host: localhost
    - port: 27017
    - require:
      - cmodule: test_mongodb_find
