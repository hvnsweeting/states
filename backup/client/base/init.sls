{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - bash
  - local
  - hostname
  - salt.minion.deps

/usr/local/bin/grandfather-father-son.py:
  file:
    - managed
    - user: root
    - group: root
    - mode: 555
    - source: salt://backup/gen_name.py
    - require:
      - host: hostname
      - file: /usr/local
      - file: bash

/usr/local/bin/backup-file:
  file:
    - managed
    - user: root
    - group: root
    - mode: 500
    - template: jinja
    - source: salt://backup/file.jinja2
    - require:
      - host: hostname
      - file: /usr/local
      - file: bash
      - file: /usr/local/bin/grandfather-father-son.py

/usr/local/bin/backup-validate:
  file:
    - managed
    - user: root
    - group: root
    - mode: 500
    - template: jinja
    - source: salt://backup/client/validate.jinja2
    - require:
      - file: /usr/local
      - file: bash
      {#- for unzip #}
      - pkg: salt_minion_deps
