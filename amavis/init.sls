{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "os.jinja2" import os with context %}
{%- from 'macros.jinja2' import manage_pid with context %}
include:
  - amavis.common
  - apt
  - bash
  - cron
  - locale
  - mail
  - spamassassin

extend:
  amavis:
    pkg:
      - latest
      - name: amavisd-new
      - require:
        - cmd: apt_sources
        - file: /etc/mailname
        - cmd: system_locale
    service:
      - running
      - order: 50
      - watch:
        - pkg: amavis
        - user: amavis
      - require:
        - cmd: pyzor_test

/etc/amavis/conf.d/50-user:
  file:
    - managed
    - source: salt://amavis/config.jinja2
    - template: jinja
    - mode: 440
    - watch_in:
      - service: amavis

/etc/cron.daily/amavisd-new:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 500
    - require:
      - pkg: cron
      - file: bash
      - pkg: amavis
{%- if os.is_precise %}
    - source: salt://amavis/cron_daily.jinja2
{%- else %}
    - source: salt://amavis/cron_clean_quarantined.jinja2

/var/lib/amavis/.spamassassin:
  file:
    - directory
    - user: amavis
    - group: amavis
    - mode: 700
    - require:
      - user: amavis

/var/lib/amavis/.spamassassin/user_prefs:
  file:
    - managed
    - user: amavis
    - group: amavis
    - mode: 640
    - replace: False
    - require:
      - file: /var/lib/amavis/.spamassassin
    - require_in:
      - pkg: amavis
{%- endif %}

{%- call manage_pid('/var/run/amavis/amavisd.pid', 'amavis', 'amavis', 'amavis', 640) %}
- pkg: amavis
{%- endcall %}
