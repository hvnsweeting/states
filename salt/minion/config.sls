{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

/etc/salt/minion.d:
  file:
    - directory
    - user: root
    - group: root
    - mode: 750

/etc/salt/minion:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 444
    - source: salt://salt/minion/config.jinja2

{%- for file in ('master', 'logging', 'graphite', 'mysql', 's3') %}
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
{%- endfor %}
