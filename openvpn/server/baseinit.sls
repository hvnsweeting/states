{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'openvpn/server/macro.jinja2' import service_openvpn with context -%}
{%- from 'macros.jinja2' import dict_default with context %}
{%- from 'upstart/absent.sls' import upstart_absent with context %}

include:
  - apt
  - openvpn
  - rsyslog
  - salt.minion.deps
  - openssl

/etc/default/openvpn:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://openvpn/server/default.jinja2
    - require:
      - pkg: openvpn

/usr/share/openvpn/up.sh:
  file:
    - absent

/usr/share/openvpn/down.sh:
  file:
    - absent

{%- for type in ('lib', 'run', 'log') %}
/var/{{ type }}/openvpn:
  file:
    - directory
    - user: root
    - group: root
    - mode: 770
{%- endfor -%}

{%- set ca_name = salt['pillar.get']('openvpn:ca:name') -%}
{%- set bits = salt['pillar.get']('openvpn:ca:bits') -%}
{%- set country = salt['pillar.get']('openvpn:ca:country') -%}
{%- set state = salt['pillar.get']('openvpn:ca:state') -%}
{%- set locality = salt['pillar.get']('openvpn:ca:locality') -%}
{%- set organization = salt['pillar.get']('openvpn:ca:organization') -%}
{%- set organizational_unit = salt['pillar.get']('openvpn:ca:organizational_unit') -%}
{%- set email = salt['pillar.get']('openvpn:ca:email') -%}
{%- set servers = salt['pillar.get']('openvpn:servers', {}) %}

openvpn_dh:
  cmd:
    - run
    - name: openssl dhparam -out /etc/openvpn/dh.pem {{ salt['pillar.get']('openvpn:dhparam:key_size', 2048) }}
    - unless: test -f /etc/openvpn/dh.pem
    - require:
      - pkg: openssl
      - pkg: openvpn

{%- set upstart_files = salt['file.find'](path='/etc/init/', regex='openvpn-(?!client).+\.conf', type='f', print='name') -%}
{%- for file in upstart_files if file.replace('openvpn-', '').replace('.conf', '') not in servers %}
    {%- set instance = file.replace('openvpn-', '').replace('.conf', '') %}
{{ upstart_absent('openvpn-' ~ instance) }}

openvpn_absent_old_{{ instance }}:
  file:
    - absent
    - name: /etc/openvpn/{{ instance }}
    - require:
      - service: openvpn-{{ instance }}
    {%- for server in servers %}
        {%- if loop.first %}
    - require_in:
        {%- endif %}
      - service: openvpn-{{ server }}
    {%- endfor %}
{%- endfor %}

{%- for instance in servers -%}
    {%- set config_dir = '/etc/openvpn/' + instance -%}
    {%- set client_dir = config_dir ~ '/clients' %}
    {%- set mode = servers[instance]['mode'] %}
    {{ dict_default(servers[instance], 'clients', []) }}
    {{ dict_default(servers[instance], 'revocations', []) }}

{{ config_dir }}:
  file:
    - directory
    - user: nobody
    - group: nogroup
    - mode: 550
    - require:
      - pkg: openvpn

{{ config_dir }}/clients:
  file:
    - directory
    - user: root
    - group: root
    - mode: 550
    - require:
      - file: {{ config_dir }}

openvpn_{{ instance }}_config:
  file:
    - managed
    - name: {{ config_dir }}/config
    - user: nobody
    - group: nogroup
    - source: salt://openvpn/server/{{ mode }}.jinja2
    - template: jinja
    - mode: 400
    - context:
        instance: {{ instance }}
    - watch_in:
      - service: openvpn-{{ instance }}
    - require:
      - file: {{ config_dir }}
      - pkg: salt_minion_deps

    {%- if mode == 'static' %}
        {#- only 2 remotes are supported -#}
        {%- if servers[instance]['peers']|length == 2 %}

{{ instance }}_secret:
  file:
    - managed
    - name: {{ config_dir }}/secret.key
    - contents: |
        {{ servers[instance]['secret'] | indent(8) }}
    - user: nobody
    - group: nogroup
    - mode: 400
    - require:
      - file: {{ config_dir }}
    - watch_in:
      - service: openvpn-{{ instance }}

        {%- endif %}

{%- block openvpn_instance %}
{{ service_openvpn(instance) }}
{%- endblock openvpn_instance %}

openvpn_{{ instance }}_client:
  file:
    - managed
    - name: {{ config_dir }}/client.conf
    - user: nobody
    - group: nogroup
    - source: salt://openvpn/client/{{ mode }}.jinja2
    - template: jinja
    - mode: 400
    - context:
        instance: {{ instance }}
    - require:
      - file: {{ config_dir }}
  cmd:
    - wait
    - name: zip client.zip client.conf secret.key
    - cwd: {{ config_dir }}
    - watch:
      - file: openvpn_{{ instance }}_client
      - file: {{ instance }}_secret
    - require:
      - pkg: salt_minion_deps

{{ config_dir }}/client.zip:
  file:
    - managed
    - user: root
    - group: root
    - mode: 400
    - replace: False
    - require:
      - cmd: openvpn_{{ instance }}_client

    {%- elif servers[instance]['mode'] == 'tls' %}

      {%- set ca_crt = servers[instance]['ca_crt'] | default(None) %}
openvpn_ca_crt_{{ instance }}:
      {%- if ca_crt %}
  file:
    - managed
    - name: /etc/openvpn/{{ instance }}/ca.crt
    - contents_pillar: openvpn:servers:{{ instance }}:ca_crt
    - user: root
    - group: root
    - mode: 644
      {%- else %}
  module:
    - run
    - name: tls.create_ca
    - ca_dir: '{{ config_dir }}'
    - ca_filename: 'ca'
    - ca_name: {{ ca_name }}
    - bits: {{ bits }}
    - days: {{ salt['pillar.get']('openvpn:ca:days') }}
    - CN: {{ salt['pillar.get']('openvpn:ca:common_name') }}
    - C: {{ country }}
    - ST: {{ state }}
    - L: {{ locality }}
    - O: {{ organization }}
    - OU: {{ organizational_unit }}
    - emailAddress: {{ email }}
    - unless: test -f {{ config_dir }}/ca.crt
      {%- endif %}
    - require:
      - pkg: salt_minion_deps
      - file: {{ config_dir }}

      {%- set ca_key = servers[instance]['ca_key'] | default(None) %}
openvpn_ca_key_{{ instance }}:
  file:
    - managed
    - name: /etc/openvpn/{{ instance }}/ca.key
      {%- if ca_key %}
    - contents_pillar: openvpn:servers:{{ instance }}:ca_key
      {%- else %}
    - replace: False
      {%- endif %}
    - user: root
    - group: root
    - mode: 400
    - require:
      - file: {{ config_dir }}
      {%- if not ca_crt %}
      - module: openvpn_ca_crt_{{ instance }}
      {%- endif %}

openvpn_create_empty_crl_{{ instance }}:
  module:
    - run
    - name: tls.create_empty_crl
    - ca_dir: '/etc/openvpn/{{ instance }}'
    - ca_filename: 'ca'
    - ca_name: {{ ca_name }}
    - crl_file: '/etc/openvpn/{{ instance }}/crl.pem'
    - unless: test -f /etc/openvpn/{{ instance }}/crl.pem
    - require:
      {%- if ca_crt %}
      - file: openvpn_ca_crt_{{ instance }}
      {%- else %}
      - module: openvpn_ca_crt_{{ instance }}
      {%- endif %}
      - file: openvpn_ca_key_{{ instance }}

      {%- set server_csr = servers[instance]['server_csr'] | default(None) %}
openvpn_server_csr_{{ instance }}:
      {%- if server_csr %}
  file:
    - managed
    - name: /etc/openvpn/{{ instance }}/server.csr
    - contents_pillar: openvpn:servers:{{ instance }}:server_csr
    - user: root
    - group: root
    - mode: 644
      {%- else %}
  module:
    - run
    - name: tls.create_csr
    - ca_name: {{ ca_name }}
    - ca_dir: '{{ config_dir }}'
    - ca_filename: 'ca'
    - cert_dir: '/etc/openvpn/{{ instance }}'
    - bits: {{ bits }}
    - CN: server
    - C: {{ country }}
    - ST: {{ state }}
    - L: {{ locality }}
    - O: {{ organization }}
    - OU: {{ organizational_unit }}
    - emailAddress: {{ email }}
    - unless: test -f /etc/openvpn/{{ instance }}/server.csr
      {%- endif %}
    - require:
      - file: {{ config_dir }}
      {%- if not ca_crt %}
      - module: openvpn_ca_crt_{{ instance }}
      {%- endif %}

      {%- set server_crt = servers[instance]['server_crt'] | default(None) %}
openvpn_server_crt_{{ instance }}:
      {%- if server_crt %}
  file:
    - managed
    - name: /etc/openvpn/{{ instance }}/server.crt
    - contents_pillar: openvpn:servers:{{ instance }}:server_crt
    - user: root
    - group: root
    - mode: 644
      {%- else %}
  module:
    - wait
    - name: tls.create_ca_signed_cert
    - ca_name: {{ ca_name }}
    - CN: server
    - ca_dir: '{{ config_dir }}'
    - ca_filename: 'ca'
    - cert_dir: '/etc/openvpn/{{ instance }}'
    - extensions:
        basicConstraints:
          critical: False
          options: 'CA:FALSE'
        keyUsage:
          critical: False
          options: 'Digital Signature, Key Encipherment'
        extendedKeyUsage:
          critical: False
          options: 'serverAuth'
    - watch:
      - module: openvpn_server_csr_{{ instance }}
      {%- endif %}
    - require:
      - file: {{ config_dir }}
    - watch_in:
      - service: openvpn-{{ instance }}

      {%- set server_key = servers[instance]['server_key'] | default(None) %}
openvpn_server_key_{{ instance }}:
  file:
    - managed
    - name: /etc/openvpn/{{ instance }}/server.key
      {%- if server_key %}
    - contents_pillar: openvpn:servers:{{ instance }}:server_key
      {%- else %}
    - replace: False
      {%- endif %}
    - user: root
    - group: root
    - mode: 400
    - require:
      - file: {{ config_dir }}
      {%- if not server_crt %}
      - module: openvpn_server_crt_{{ instance }}
      {%- endif %}
    - require_in:
      - service: openvpn-{{ instance }}

{{ config_dir }}/ccd:
  file:
    - directory
    - user: nobody
    - group: nogroup
    - mode: 550
    - require:
      - file: {{ config_dir }}

        {%- set server_octets = servers[instance]['server'].split()[0].split('.') %}
        {%- set server_last_octet = server_octets[3]|int + 1 %}
        {%- set clients = [] %}

        {%- for client in servers[instance]['clients'] -%}
            {%- if client not in servers[instance]['revocations'] -%}
                {%- if client is mapping -%}
                    {{ dict_default(servers[instance], 'topology', 'subnet') }}
                    {%- set topology = servers[instance]['topology'] %}
                    {%- set client, client_ip = servers[instance]['clients'][loop.index0].items()[0] %}

{{ config_dir }}/ccd/{{ client }}:
  file:
    - managed
    - user: nobody
    - group: nogroup
    - mode: 400
    - contents: |
        # {{ salt['pillar.get']('message_do_not_modify') }}

                    {%- if topology == "subnet" %}
        ifconfig-push {{ client_ip }} {{ servers[instance]['server'].split()[1] }}
                    {%- elif topology == "net30" %}
                        {%- set client_octets = client_ip.split('.') -%}
                        {%- set server_last_octet = client_octets[3]|int + 1 %}
        ifconfig-push {{ client_ip }} {{ client_octets[0] + "." + client_octets[1] + "." + client_octets[2] + "." + server_last_octet|string }}
                    {%- endif %}
    - require:
      - file: {{ config_dir }}/ccd
    - require_in:
      - service: openvpn-{{ instance }}
                {%- endif %}
                {%- do clients.append(client) %}

openvpn_client_csr_{{ instance }}_{{ client }}:
  module:
    - run
    - name: tls.create_csr
    - ca_name: {{ ca_name }}
    - ca_dir: '/etc/openvpn/{{ instance }}'
    - ca_filename: 'ca'
    - cert_dir: '/etc/openvpn/{{ instance }}/clients'
    - bits: {{ bits }}
    - CN: {{ client }}
    - C: {{ country }}
    - ST: {{ state }}
    - L: {{ locality }}
    - O: {{ organization }}
    - OU: {{ organizational_unit }}
    - emailAddress: {{ email }}
    - unless: test -f /etc/openvpn/{{ instance }}/clients/{{ client }}.crt
    - require:
      {%- if ca_crt %}
      - file: openvpn_ca_crt_{{ instance }}
      {%- else %}
      - module: openvpn_ca_crt_{{ instance }}
      {%- endif %}
      - file: openvpn_ca_key_{{ instance }}
      - file: {{ config_dir }}/clients

openvpn_client_cert_{{ instance }}_{{ client }}:
  module:
    - wait
    - name: tls.create_ca_signed_cert
    - ca_name: {{ ca_name }}
    - CN: {{ client }}
    - ca_dir: '/etc/openvpn/{{ instance }}'
    - ca_filename: 'ca'
    - cert_dir: '/etc/openvpn/{{ instance }}/clients'
    - extensions:
        basicConstraints:
          critical: False
          options: 'CA:FALSE'
        keyUsage:
          critical: False
          options: 'Digital Signature'
        extendedKeyUsage:
          critical: False
          options: 'clientAuth'
    - require:
      - file: {{ config_dir }}/clients
    - watch:
      - module: openvpn_client_csr_{{ instance }}_{{ client }}
  file:
    - managed
    - name: /etc/openvpn/{{ instance }}/clients/{{ client }}.key
    - user: root
    - group: root
    - mode: 400
    - replace: False
    - require:
      - module: openvpn_client_cert_{{ instance }}_{{ client }}

openvpn_{{ instance }}_{{ client }}:
  file:
    - managed
    - name: {{ config_dir }}/clients/{{ client }}.conf
    - user: root
    - group: root
    - source: salt://openvpn/client/{{ servers[instance]['mode'] }}.jinja2
    - template: jinja
    - mode: 400
    - context:
        instance: {{ instance }}
        client: {{ client }}
    - require:
      - file: {{ config_dir }}
  cmd:
    - wait
    - name: zip -j {{ client }}.zip {{ client }}.conf {{ client }}.crt {{ client }}.key /etc/openvpn/{{ instance }}/ca.crt
    - cwd: {{ config_dir }}/clients
    - watch:
      - file: openvpn_{{ instance }}_{{ client }}
      {%- if ca_crt %}
      - file: openvpn_ca_crt_{{ instance }}
      {%- else %}
      - module: openvpn_ca_crt_{{ instance }}
      {%- endif %}
      - module: openvpn_client_cert_{{ instance }}_{{ client }}
    - require:
      - pkg: salt_minion_deps

{{ config_dir }}/clients/{{ client }}.zip:
  file:
    - managed
    - user: root
    - group: root
    - mode: 400
    - replace: False
    - watch:
      - cmd: openvpn_{{ instance }}_{{ client }}
            {%- endif %}{# client cert not in revocation list -#}
        {%- endfor %}{# client cert -#}

        {#- Revoke clients certificate -#}
        {%- for r_client in servers[instance]['revocations'] %}
openvpn_revoke_client_cert_{{ instance }}_{{ r_client }}:
  module:
    - run
    - name: tls.revoke_cert
    - ca_name: {{ ca_name }}
    - ca_dir: '/etc/openvpn/{{ instance }}'
    - ca_filename: 'ca'
    - CN: {{ r_client }}
    - cert_dir: '/etc/openvpn/{{ instance }}/clients'
    - crl_file: '{{ config_dir }}/crl.pem'
    - unless: grep '^R.*CN={{ r_client }}' /etc/openvpn/index.txt
    - require:
      - pkg: salt_minion_deps
      - module: openvpn_create_empty_crl_{{ instance }}
    - require_in:
      - service: openvpn-{{ instance }}
        {%- endfor -%}

        {#- Delete all client certs that is not in the client list anymore -#}
        {%- set client_files = salt['file.find'](path='/etc/openvpn/' ~ instance ~ '/clients', name='*.conf', type='f', print='name') -%}
        {%- for file in client_files if file.replace('.conf', '') not in clients -%}
            {%- set client = file.replace('.conf', '') %}
openvpn_absent_old_client_{{ instance }}_{{ client }}:
  file:
    - absent
    - names:
            {%- for ext in ('conf', 'crt', 'csr', 'key', 'zip') %}
      - /etc/openvpn/{{ instance }}/clients/{{ client }}.{{ ext }}
            {%- endfor %}
        {%- endfor %}

{%- call service_openvpn(instance) %}
      - cmd: openvpn_dh
      - file: openvpn_{{ instance }}_config
      {%- if ca_crt %}
      - file: openvpn_ca_crt_{{ instance }}
      {%- else %}
      - module: openvpn_ca_crt_{{ instance }}
      {%- endif %}
      - file: openvpn_ca_key_{{ instance }}
      {%- if server_crt %}
      - file: openvpn_server_crt_{{ instance }}
      {%- else %}
      - module: openvpn_server_crt_{{ instance }}
      {%- endif %}
      - file: /etc/default/openvpn
{%- endcall -%}
    {%- endif %}{# tls -#}
{%- endfor -%}
