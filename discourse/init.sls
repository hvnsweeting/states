include:
  - docker
  - git
  - postgresql.server
  - postgresql.server.contrib
  - redis

/usr/local/discourse:
  file:
    - directory

discourse:
  git:
    - latest
    - name: https://github.com/discourse/discourse_docker.git
    - target: /usr/local/discourse
    - rev: master
    - require:
      - pkg: git
      - file: /usr/local/discourse
  file:
    - managed
    - name: /usr/local/discourse/containers/app.yml
    - source: salt://discourse/dockerfile.jinja2
    - mode: 440
    - template: jinja
    - user: root
    - group: root
    - require:
      - file: /usr/local/discourse
  postgres_user:
    - present
    - name: discourse
    - password: {{ salt['password.pillar']('discourse:db:password', 10) }}
    - runas: postgres
    - require:
      - service: postgresql
  postgres_database:
    - present
    - name: discourse
    - owner: discourse
    - runas: postgres
    - require:
      - postgres_user: discourse
      - service: postgresql
      - pkg: postgresql_contrib
  postgres_extension:
    - present
    - name: hstore
    - runas: postgres
    - maintenance_db: template1
    - require:
      - postgres_user: discourse
      - service: postgresql

discourse_postgresql_hstore:
  postgres_extension:
    - present
    - name: hstore
    - runas: postgres
    - maintenance_db: discourse
    - require:
      - postgres_user: discourse
      - service: postgresql

discourse_postgresql_pg_trgm_template1:
  postgres_extension:
    - present
    - name: pg_trgm
    - maintenance_db: template1
    - runas: postgres
    - require:
      - postgres_user: discourse
      - service: postgresql

discourse_postgresql_pg_trgm:
  postgres_extension:
    - present
    - name: pg_trgm
    - maintenance_db: discourse
    - runas: postgres
    - require:
      - postgres_user: discourse
      - service: postgresql

discourse_bootstrap:
  cmd:
    - wait
    - cwd: /usr/local/discourse
    - name: ./launcher bootstrap app
    - require:
      - service: redis
      - postgres_database: discourse
    - watch:
      - file: discourse
      - pip: docker

discourse_start:
  cmd:
    - run
    - cwd: /usr/local/discourse
    - name: ./launcher start app
    - require:
      - cmd: discourse_bootstrap
