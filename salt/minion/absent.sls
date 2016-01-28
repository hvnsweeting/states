{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "upstart/absent.sls" import upstart_absent with context -%}
{{ upstart_absent('salt-minion') }}

extend:
  salt-minion:
    file:
      - absent
      - name: /etc/salt/minion
      - require:
        - pkg: salt-minion

salt_minion_absent_cache_dir:
  file:
    - absent
    - name: /var/cache/salt/minion
    - require:
      - pkg: salt-minion

salt_minion_config:
  file:
    - absent
    - name: /etc/salt/minion.d
    - require:
      - pkg: salt-minion
