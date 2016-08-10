{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

nodejs:
  pkg:
    - purged
  file:
    - absent
    - names:
      - /etc/apt/sources.list.d/nodejs.list
      - /usr/share/man/man1/js.1.gz
      - /etc/alternatives/js
      - /etc/alternatives/js.1.gz
      - /usr/bin/js
