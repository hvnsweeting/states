{#- Usage of this is governed by a license that can be found in doc/license.rst -#}
{# -*- ci-automatic-discovery: off -*-
This formula needs a working DNS authoritative server to work, it
will be tested with bind in test.sls
#}

include:
  - pip
  - salt.minion.deps

ddns_dnspython:
  pip:
    - installed
    - name: dnspython
    - reload_modules: True
    - require:
      - module: pip

ddns_tsig_key:
  file:
    - managed
    - name: {{ opts['cachedir'] }}/ddns
    - template: jinja
    - source: salt://ddns/tsig.jinja2
    - user: root
    - group: root
    - mode: 400

{%- set zone = salt['pillar.get']('ddns:zone') %}
{%- set ttl = salt['pillar.get']('ddns:ttl', 3600) %}
{%- set nameserver = salt['pillar.get']('ddns:nameserver') %}
{%- set domains = salt['pillar.get']('ddns:domains', None)|default({grains['id']:{}}, boolean=True) %}
{%- set interface = salt['pillar.get']('network_interface', 'eth0') %}
{%- for domain in domains %}
  {%- set ips = salt['pillar.get']('ddns:domains:' ~ domain ~ ':ips', None) | default(salt['network.ip_addrs'](interface), boolean=True) %}
  {%- for ip in ips %}
ddns_setup_dynamic_dns_{{ domain }}_{{ loop.index }}:
  ddns:
    - present
    - name: {{ domain }}
    - zone: {{ zone }}
    - ttl: {{ ttl }}
    - nameserver: {{ nameserver }}
    - data: {{ ip }}
    - keyfile: {{ opts['cachedir'] }}/ddns
    - watch:
      - file: ddns_tsig_key
    - require:
      - pip: ddns_dnspython
  {%- endfor %}
  {#- Remove all A records that is not in the pillar anymore #}
  {%- for addr in salt['dnsutil.A'](domain ~ '.' ~ zone, nameserver=nameserver) if addr not in ips %}
ddns_{{ domain }}_absent_old_ip_{{ loop.index }}:
  ddns:
    - absent
    - name: {{ domain }}
    - zone: {{ zone }}
    - ttl: {{ ttl }}
    - nameserver: {{ nameserver }}
    - data: {{ addr }}
    - keyfile: {{ opts['cachedir'] }}/ddns
    - watch:
      - file: ddns_tsig_key
    - require:
      - pip: ddns_dnspython
      - pkg: salt_minion_deps
  {%- endfor %}
{%- endfor %}
