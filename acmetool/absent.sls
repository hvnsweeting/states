{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

acmetool:
  pkg:
    - purged
  file:
    - absent
    - name: {{ opts['cachedir'] }}/acmetool_response
    - require:
      - pkg: acmetool

/var/lib/acme:
  file:
    - absent
