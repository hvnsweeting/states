{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - cron

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- set debfile = 'acmetool_0.0.58-1trusty1_amd64.deb' %}

acmetool:
  pkg:
    - installed
    - sources:
  {%- if files_archive %}
      - acmetool: {{ files_archive|replace('file://', '')|replace('https://', 'http://') }}/mirror/{{ debfile }}
  {%- else %}
      {#- source: ppa: hlandau/rhea #}
      - acmetool: https://archive.robotinfra.com/mirror/{{ debfile }}
  {%- endif %}
    - require:
      - cmd: apt_sources
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - name: /var/lib/acme/conf/responses
    - source: salt://acmetool/response.jinja2
    - require:
      - pkg: acmetool

{%- for name in salt['pillar.get']('ssl:certs', {}) %}
  {%- if salt['pillar.get']('ssl:certs:' ~ name ~ ':letsencrypt', False) %}
acmetool_domains_{{ name }}:
  cmd:
    - run
    - name: acmetool want {{ name }}
    - require:
      - file: acmetool
    - require_in:
      - file: acmetool_renew_config
  {%- endif %}
{%- endfor %}

acmetool_renew_config:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - name: /var/lib/acme/conf/target
    - source: salt://acmetool/config.jinja2

acmetool_cron_renew_certs:
  file:
    - managed
    - name: /etc/cron.d/acmetool
    - source: salt://acmetool/cron.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: cron
      - file: acmetool_renew_config
