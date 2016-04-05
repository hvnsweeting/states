{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - pppd
  - kernel.modules
  - rsyslog
  - sysctl

{%- set instances = salt['pillar.get']('pppd:instances', {}) -%}
{%- set pptpd = instances.get('pptpd', {}) -%}
{%- set encryption = pptpd.get('encryption', {}) %}

pptpd:
  pkg:
    - installed
    - require:
      - cmd: apt_sources
      - pkg: ppp
  file:
    - managed
    - name: /etc/pptpd.conf
    - source: salt://pptpd/config.jinja2
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: pptpd
  service:
    - running
    - enable: True
    - sig: /usr/sbin/pptpd
    - watch:
      - pkg: pptpd
      - file: pptpd
      {#- requires specific pillar key, look in pptpd/doc/pillar.rst #}
      - file: ppp-options-pptpd
    - require:
      - service: rsyslog
      {#- requires specific pillar key, look in pptpd/doc/pillar.rst #}
      - file: sysctl
      {#- requires specific pillar key, look in pptpd/doc/pillar.rst #}
{%- if 'mppe-128' in encryption.get('require', []) %}
      - kmod: kernel_module_ppp_mppe
{%- endif %}
