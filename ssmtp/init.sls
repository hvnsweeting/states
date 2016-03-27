{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - hostname
  - rsyslog

ssmtp:
  pkg:
    - installed
    - require:
      - service: rsyslog
      - cmd: apt_sources
      - debconf: ssmtp
      - host: hostname
  debconf:
    - set
    - data:
        'ssmtp/mailhub': {'type': 'string', 'value': '{{ salt['pillar.get']('smtp:server') }}'}
{%- set mailname = salt['pillar.get']('mail:mailname') %}
        'ssmtp/hostname': {'type': 'string', 'value': '{{ mailname }}'}
        'ssmtp/root': {'type': 'string', 'value': '{{ salt['pillar.get']('smtp:root') }}'}
        'ssmtp/rewritedomain': {'type': 'string', 'value': ''}
        {# unused by the package itself, why? #}
        'ssmtp/overwriteconfig': {'type': 'boolean', 'value': False}
        'ssmtp/mailname': {'type': 'string', 'value': '{{ mailname }}'}
        'ssmtp/port': {'type': 'string', 'value': '{{ salt['pillar.get']('smtp:port') }}'}
        'ssmtp/fromoverride': {'type': 'boolean', 'value': False}
    - require:
      - pkg: apt_sources

bsd-mailx:
  pkg:
    - installed
    - require:
      - pkg: ssmtp
      - cmd: apt_sources

{%- set smtp_user = salt['pillar.get']('smtp:user', None) %}
{%- set smtp_passwd = salt['pillar.get']('smtp:password', None) %}

/etc/ssmtp/ssmtp.conf:
  file:
    - managed
    - template: jinja
    - source: salt://ssmtp/config.jinja2
    - user: root
    - group: root
    - mode: 644
    - context:
        smtp_user: {{ smtp_user }}
        smtp_passwd: {{ smtp_passwd }}
    - show_diff: False
    - require:
      - pkg: bsd-mailx
      - pkg: ssmtp

/etc/ssmtp/revaliases:
  file:
{%- if smtp_user and smtp_passwd %}
    - managed
    - template: jinja
    - source: salt://ssmtp/revaliases.jinja2
    - user: root
    - group: root
    - mode: 644
{%- else %}
    - absent
{%- endif %}
    - require:
      - pkg: bsd-mailx
      - pkg: ssmtp
