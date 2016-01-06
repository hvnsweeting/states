{#- Usage of this is governed by a license that can be found in doc/license.rst

This state is the most simple way to upgrade to restart a minion.
It don't requires on any other state (sls) file except salt
(for the repository).

It's kept at the minion to make sure it don't change anything else during the
upgrade process.
-#}

include:
  - apt
  - salt
  - salt.minion.config

salt-minion:
  file:
    - managed
    - name: /etc/init/salt-minion.conf
    - template: jinja
    - source: salt://salt/minion/upstart.jinja2
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: salt-minion
  pkg:
    - latest
    - require:
      - file: /etc/salt/minion.d
      - file: /etc/salt/minion
  service:
    - running
    - enable: True
    - skip_verify: True
    - require:
      - file: /var/cache/salt
    - watch:
      - pkg: salt-minion
      - file: /etc/salt/minion
      - file: /etc/salt/minion.d
      - file: salt-minion
      - cmd: salt
{%- for file in ('master', 'logging', 'graphite', 'mysql', 's3') %}
      - file: /etc/salt/minion.d/{{ file }}.conf
{%- endfor %}
