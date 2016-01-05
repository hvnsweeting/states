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

/etc/salt/minion:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 444
    - source: salt://salt/minion/config.jinja2
    - require_in:
      - pkg: salt-minion

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
  service:
    - running
    - enable: True
    - skip_verify: True
    - require:
      - file: /var/cache/salt
    - watch:
      - pkg: salt-minion
      - file: /etc/salt/minion
      - file: salt-minion
      - cmd: salt

/etc/salt/minion.d:
  file:
    - directory
    - user: root
    - group: root
    - mode: 750
    - require_in:
      - pkg: salt-minion
    - watch_in:
      - service: salt-minion

{%- for file in ('master', 'logging', 'graphite', 'mysql', 's3') %}
  {%- if (file == 'graphite' and salt['pillar.get']('graphite_address', False)) or file != 'graphite' %}
/etc/salt/minion.d/{{ file }}.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://salt/minion/{{ file }}.jinja2
    - require:
      - file: /etc/salt/minion.d
    - require_in:
      - pkg: salt-minion
    - watch_in:
      - service: salt-minion
  {%- endif %}
{%- endfor %}
