{#- Usage of this is governed by a license that can be found in doc/license.rst -#}
{%- set ssl = salt['pillar.get']('discourse:ssl', False) %}

include:
  - docker
  - git
  - nginx
  - postgresql.server
  - postgresql.server.contrib
  - redis
{% if ssl %}
  - ssl
{% endif %}

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
      - git: discourse
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
    - unless: docker ps | grep ' app'
    - require:
      - cmd: discourse_bootstrap

/etc/nginx/conf.d/discourse.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: www-data
    - mode: 400
    - source: salt://nginx/proxy.jinja2
    - require:
      - pkg: nginx
      - cmd: discourse_start
    - context:
        destination: http://127.0.0.1:8080
        ssl: {{ salt['pillar.get']('discourse:ssl', False) }}
        ssl_redirect: {{ salt['pillar.get']('discourse:ssl_redirect', False) }}
        hostnames: {{ salt['pillar.get']('discourse:hostnames') }}
    - watch_in:
      - service: nginx

{% if salt['pillar.get']('discourse:ssl', False) %}
extend:
  nginx:
    service:
      - watch:
        - cmd: ssl_cert_and_key_for_{{ salt['pillar.get']('discourse:ssl', False) }}
{% endif %}
