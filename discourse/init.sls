include:
  - docker
  - git

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

discourse_bootstrap:
  cmd:
    - wait
    - cwd: /usr/local/discourse
    - name: ./launcher bootstrap app
    - watch:
      - file: discourse
      - pip: docker

discourse_start:
  docker:
    - running
    - container: app
    - require:
      - cmd: discourse_bootstrap
