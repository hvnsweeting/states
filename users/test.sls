include:
  - doc
  - users

test:
  qa:
    - test_pillar
    - name: users
    - doc: {{ opts['cachedir'] }}/doc/output
    - order: last
    - require:
      - cmd: doc
