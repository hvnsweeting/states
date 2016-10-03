{#- Usage of this is governed by a license that can be found in doc/license.rst -#}
{%- set use_letsencrypt = salt['pillar.get']('ssl:letsencrypt_admin_email', None) %}

include:
  - apt
  - openssl
{%- if use_letsencrypt %}
  - acmetool
{%- endif %}

ssl-cert:
  pkg:
    - latest
    - require:
      - cmd: apt_sources
      - pkg: openssl

{#-
package ca-certificates can't be removed because salt-minion require it,
this command is for regenerating ssl-cert because /etc/ssl/certs is remove in ssl.absent
Visa_eCommerce_Root.pem is one of valid cert in /usr/share/ca-certificates
#}
ca-certificates:
  pkg:
    - latest
    - require:
      - pkg: ssl-cert
  cmd:
    - run
    - name: update-ca-certificates
    - require:
      - pkg: ca-certificates
    - unless: test -f /etc/ssl/certs/Visa_eCommerce_Root.pem

/etc/ssl/openssl.cnf:
  file:
    - exists
    - require:
      - pkg: ssl-cert

ssl_dhparam:
  cmd:
    - run
    - name: openssl dhparam -out /etc/ssl/dhparam.pem {{ salt['pillar.get']('ssl:dhparam:key_size', 2048) }}
    - unless: test -f /etc/ssl/dhparam.pem
    - require:
      - pkg: openssl
      - pkg: ssl-cert
  file:
    - managed
    - name: /etc/ssl/dhparam.pem
    - replace: False
    - user: root
    - group: ssl-cert
    - mode: 440
    - require:
      - cmd: ssl_dhparam

/etc/ssl/private:
  file:
    - directory
    - user: root
    - group: ssl-cert
    - mode: 710
    - require:
      - pkg: ssl-cert

{%- macro manage_ssl(name, cert_from_letsencrypt=False) %}
# managing SSL from pillar or generate by letsencrypt
{%- if not cert_from_letsencrypt %}
  {%- set server_key = salt['pillar.get']('ssl:certs:' + name + ':server_key') | indent(8) -%}
  {%- set server_crt = salt['pillar.get']('ssl:certs:' + name + ':server_crt') | indent(8) -%}
  {%- set ca_crt = salt['pillar.get']('ssl:certs:' + name + ':ca_crt') | indent(8) %}
{%- else %}
acmetool_set_group: {# API, for using by ssl-cert group #}
  cmd:
    - run
    - name: find /var/lib/acme/keys/ -type d -exec chown -R root:ssl-cert {} \;
    - require:
      - file: acmetool_renew_config
      - pkg: ssl-cert
    - require_in:
      - cmd: ssl_create_symlink_by_hash
{%- endif %}


/etc/ssl/private/{{ name }}.key:
  file:
{%- if not cert_from_letsencrypt %}
    - managed
    - contents: |
        {{ server_key }}
    - mode: 440
    - user: root
    - group: ssl-cert
{% else %}
    - symlink
    - target: /var/lib/acme/live/{{ name }}/privkey
{% endif %}
    - require:
      - pkg: ssl-cert
      - file: /etc/ssl/private

/etc/ssl/certs/{{ name }}.crt:
  file:
{%- if not cert_from_letsencrypt %}
    - managed
    - contents: |
        {{ server_crt }}
    - user: root
    - group: ssl-cert
    - mode: 444
{% else %}
    - symlink
    - target: /var/lib/acme/live/{{ name }}/cert
{% endif %}
    - require:
      - pkg: ssl-cert
    - watch_in:
      - cmd: ssl_create_symlink_by_hash

/etc/ssl/certs/{{ name }}_ca.crt:
  file:
{% if not cert_from_letsencrypt %}
    - managed
    - contents: |
        {{ ca_crt }}
    - user: root
    - group: ssl-cert
    - mode: 444
  {%- if ca_crt == "" %}
    - replace: False
  {%- endif %}
{% else %}
    - symlink
    - target: /var/lib/acme/live/{{ name }}/chain
{% endif %}
    - require:
      - pkg: ssl-cert
    - watch_in:
      - cmd: ssl_create_symlink_by_hash

{%- if not cert_from_letsencrypt %}
{#-
Create from server private key and certificate a PEM used by most daemon
that support SSL.
#}
/etc/ssl/private/{{ name }}.pem:
  file:
    - managed
    - contents: |
        {{ server_crt }}
        {{ server_key }}
    - user: root
    - group: ssl-cert
    - mode: 440
    - require:
      - pkg: ssl-cert
      - file: /etc/ssl/private

{%- endif %}
{#-
Some browsers may complain about a certificate signed by a well-known
certificate authority, while other browsers may accept the certificate without
issues. This occurs because the issuing authority has signed the server
certificate using an intermediate certificate that is not present in the
certificate base of well-known trusted certificate authorities which is
distributed with a particular browser. In this case the authority provides a
bundle of chained certificates which should be concatenated to the signed server
certificate. The server certificate must appear before the chained certificates
in the combined file:
#}
/etc/ssl/certs/{{ name }}_chained.crt:
  file:
{%- if not cert_from_letsencrypt %}
    - managed
    - contents: |
        {{ server_crt }}
        {{ ca_crt }}
    - user: root
    - group: ssl-cert
    - mode: 444
{% else %}
    - symlink
    - target: /var/lib/acme/live/{{ name }}/fullchain
{% endif %}
    - require:
      - pkg: ssl-cert
    - watch_in:
      - cmd: ssl_create_symlink_by_hash

{#- as service need to watch all cert files, use this cmd as trigger that
    service restart everywhen cert files changed #}
ssl_cert_and_key_for_{{ name }}:
  cmd:
    - wait
    - name: echo managed ssl cert and dhparam for {{ name }}
    - watch:
      - file: /etc/ssl/private/{{ name }}.key
      - file: /etc/ssl/certs/{{ name }}.crt
      - file: /etc/ssl/certs/{{ name }}_ca.crt
      - file: /etc/ssl/certs/{{ name }}_chained.crt
    - require:
      - cmd: ssl_create_symlink_by_hash
      - file: ssl_dhparam
{%- endmacro %}

{% for name in salt['pillar.get']('ssl:certs', {}) -%}
/etc/ssl/{{ name }}:
  file:
    - absent
{%- set cert_from_letsencrypt = salt['pillar.get']('ssl:certs:' ~ name ~ ':letsencrypt', False) and use_letsencrypt %}
{{ manage_ssl(name, cert_from_letsencrypt) }}
{% endfor -%}

{#- OpenSSL expects to find each certificate in a file named by the certificate
    subject's hashed name, plus a number extension that starts with 0.

    That means you can't just drop My_Awesome_CA_Cert.pem in the directory and
    expect it to be picked up automatically. However, OpenSSL ships with
    a utility called c_rehash which you can invoke on a directory
    to have all certificates indexed with appropriately named symlinks.

    http://mislav.uniqpath.com/2013/07/ruby-openssl/#SSL_CERT_DIR #}
ssl_create_symlink_by_hash:
  cmd:
    - wait
    - name: c_rehash /etc/ssl/certs > /dev/null
    - require:
      - cmd: ca-certificates
