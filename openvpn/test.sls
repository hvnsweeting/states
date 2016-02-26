{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'diamond/macro.jinja2' import diamond_process_test with context -%}
{%- from 'macros.jinja2' import dict_default with context %}
include:
  - doc
  - openvpn.server
  - openvpn.server.backup
  - openvpn.server.backup.diamond
  - openvpn.server.backup.nrpe
  - openvpn.server.diamond
  - openvpn.server.nrpe
  - openvpn.server.pillar
  - openvpn.client
  - openvpn.client.nrpe
  - salt.minion.deps

test:
  monitoring:
    - run_all_checks
    - order: last
  qa:
    - test
    - name: openvpn.server
    - additional:
      - openvpn.server.backup
      - openvpn.client
    - doc: {{ opts['cachedir'] }}/doc/output
    - require:
      - monitoring: test
      - cmd: doc
  diamond:
    - test
    - map:
        ProcessResources:
          {{ diamond_process_test('openvpn') }}
    - require:
      - sls: openvpn.server.diamond
      - sls: openvpn.server

{%- set servers = salt['pillar.get']('openvpn:servers', {}) -%}
{%- if servers is iterable and servers | length > 0 -%}
    {%- for instance in servers -%}
        {%- set mode = servers[instance]['mode'] %}
        {{ dict_default(servers[instance], 'clients', []) }}
        {{ dict_default(servers[instance], 'revocations', []) }}
test_openvpn_{{ instance }}:
  diamond:
    - test
    - map:
        OpenVPN:
          openvpn.{{ instance }}.clients.connected: True
        {%- if mode == 'static' %}
          openvpn.{{ instance }}.global.auth_read_bytes: True
          openvpn.{{ instance }}.global.tcp-udp_read_bytes: True
          openvpn.{{ instance }}.global.tcp-udp_write_bytes: True
          openvpn.{{ instance }}.global.tun-tap_read_bytes: True
          openvpn.{{ instance }}.global.tun-tap_write_bytes: True
        {%- else %}
          openvpn.{{ instance }}.global.max_bcast-mcast_queue_length: True
        {%- endif %}
    - require:
      - sls: openvpn.server.diamond
      - sls: openvpn.server

        {%- if mode == 'tls' -%}
        {#-
        Testing conectivity by:
          - start the client
          - wait for a while
          - grep the status file for the client's common name
        #}
test_openvpn_refresh_pillar_{{ instance }}:
  module:
    - wait
    - name: saltutil.refresh_pillar
    - watch:
      - file: openvpn_pillar
    - watch_in:
      - file: /etc/openvpn/client/{{ instance }}/ca.crt
      - file: /etc/openvpn/client/{{ instance }}/{{ grains['id'] }}.crt
      - file: /etc/openvpn/client/{{ instance }}/{{ grains['id'] }}.key
      - file: /etc/openvpn/client/{{ instance }}/{{ grains['id'] }}.conf
    - require_in:
      - file: nsca-openvpn.client
      - monitoring: openvpn.client-monitoring

            {%- for client in servers[instance]['clients'] -%}
                {%- if client not in servers[instance]['revocations'] -%}
                    {%- if client is mapping -%}
                        {%- set cn, ip = servers[instance]['clients'][loop.index0].items()[0] -%}
                    {%- else -%}
                        {%- set cn = client -%}
                    {%- endif %}
test_openvpn_tls_{{ instance }}_{{ cn }}:
  process:
    - wait
    - name: "/usr/sbin/openvpn --config /etc/openvpn/client/{{ instance }}/{{ cn }}.conf"
    - require:
      - service: openvpn_client_{{ instance }}
  cmd:
    - wait
    {#- The status file is updated every second if the __test__ pillar key is True #}
    - name: sleep 1 && grep ^{% if client is mapping %}{{ ip }},{% endif %}{{ cn }} /var/log/openvpn/{{ instance }}.log
    - watch:
      - process: test_openvpn_tls_{{ instance }}_{{ cn }}

                {%- endif %}{#- client not in revocations list -#}
            {%- endfor %}{#- clients #}
        {%- endif %}{#- tls mode -#}
    {%- endfor %}{#- instances -#}
{%- endif %}{#- servers is iterable #}

extend:
  openvpn_diamond_collector:
    file:
      - require:
        - sls: openvpn.server
