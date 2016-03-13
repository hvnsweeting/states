Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/apt/doc/index` :doc:`/apt/doc/pillar`
- :doc:`/rsyslog/doc/index` :doc:`/rsyslog/doc/pillar`
- :doc:`/ssl/doc/index` :doc:`/ssl/doc/pillar`

Mandatory
---------

Example::

  openvpn:
    ca:
      name: example
      bits: 2048
      days: 365
      common_name: example-ca
      country: US
      state: California
      locality: Redwood City
      organization: My Company Ltd
      organizational_unit: IT
      email: info@example.com

.. _pillar-openvpn-ca-name:

openvpn:ca:name
~~~~~~~~~~~~~~~

Name of the Certificate Authority.

.. _pillar-openvpn-ca-bits:

openvpn:ca:bits
~~~~~~~~~~~~~~~

Number of RSA key bits.

.. _pillar-openvpn-ca-days:

openvpn:ca:days
~~~~~~~~~~~~~~~

Number of days the Certificate Authority will be valid.

.. _pillar-openvpn-ca-country:

openvpn:ca:country
~~~~~~~~~~~~~~~~~~

Country name.

.. _pillar-openvpn-ca-state:

openvpn:ca:state
~~~~~~~~~~~~~~~~

State or Province Name.

.. _pillar-openvpn-ca-locality:

openvpn:ca:locality
~~~~~~~~~~~~~~~~~~~

Locality Name.

.. _pillar-openvpn-ca-organization:

openvpn:ca:organization
~~~~~~~~~~~~~~~~~~~~~~~

Organization Name.

.. _pillar-openvpn-ca-organizational_unit:

openvpn:ca:organizational_unit
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Organizational Unit Name.

.. _pillar-openvpn-ca-common_name:

openvpn:ca:common_name
~~~~~~~~~~~~~~~~~~~~~~

The certificate `Common Name <http://info.ssl.com/article.aspx?id=10048>`_.

.. _pillar-openvpn-ca-email:

openvpn:ca:email
~~~~~~~~~~~~~~~~

Email Address.

Optional
--------

Example::

  openvpn:
    public_interface: eth1
    dhparam:
      key_size: 2048
    servers:
      <instance>:
        topology: subnet
        mode: static
        config:
          key1: value1
          key2: value2
        peers:
          {{ grains['id'] }}:
            vpn_address: 1.1.1.1
            address: 2.2.2.1
            port:
          <peername>:
            vpn_address: 1.1.1.1
            address: 2.2.2.2
            port:
        secret:
      devops:
        mode: tls
        port: 1194
        protocol: udp
        device: tun
        server: 172.16.0.0 255.255.255.0
        ifconfig-pool: 172.16.0.1 172.16.0.9
        extra_configs:
          - client-to-client
        clients:
          - client1
          - client2
          - client3: 172.16.0.3
      devops-1:
        ca_crt: |
          -----BEGIN CERTIFICATE-----
          -----END CERTIFICATE-----
        ca_key: |
          -----BEGIN PRIVATE KEY-----
          -----END PRIVATE KEY-----
        server_csr: |
          -----BEGIN CERTIFICATE REQUEST-----
          -----END CERTIFICATE REQUEST-----
        server_key: |
          -----BEGIN PRIVATE KEY-----
          -----END PRIVATE KEY-----
        server_crt: |
          -----BEGIN CERTIFICATE-----
          -----END CERTIFICATE-----
        topology: net30
        mode: tls
        port: 1197
        protocol: udp
        device: tun
        server: 192.168.0.0 255.255.254.0
        server-ipv6: 2001:db8:0:123::/64
        ifconfig-pool: 192.168.0.5 192.168.0.9
        ifconfig-ipv6-pool: 2001:db8:0:123::4/64
        extra_configs:
          - client-to-client
        clients:
          - {{ grains['id'] }}: 192.168.0.5
      hr:
        mode: tls
        port: 1195
        protocol: udp
        device: tun
        server: 172.17.0.0 255.255.255.0
        extra_configs:
          - client-to-client

.. _pillar-openvpn-public_interface:

openvpn:public_interface
~~~~~~~~~~~~~~~~~~~~~~~~

The public interface of :doc:`/openvpn/server/doc/index`.

Default: use the value from :ref:`pillar-network-interface` (``False``).

.. _pillar-openvpn-dhparam-key_size:

openvpn:dhparam:key_size
~~~~~~~~~~~~~~~~~~~~~~~~

Number of bits of `DH
<http://en.wikipedia.org/wiki/Diffie–Hellman_key_exchange>`_ parameters.

Default: ``2048`` bits.

.. _pillar-openvpn-servers:

openvpn:servers
~~~~~~~~~~~~~~~

A dictionnary contains :doc:`index` configs.

Default: don't start any :doc:`index` ``{}`` instance.

Conditional
-----------

.. _pillar-openvpn-servers-instance:

openvpn:servers:{{ instance }}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Name of tunnel.

.. _pillar-openvpn-servers-instance-ca_crt:

openvpn:servers:{{ instance }}:ca_crt
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The :ref:`glossary-CA` certificate.

Default: generate automatically (``None``).

.. _pillar-openvpn-servers-instance-ca_key:

openvpn:servers:{{ instance }}:ca_key
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The :ref:`glossary-CA` key.

Default: generate automatically (``None``).

.. _pillar-openvpn-servers-instance-server_csr:

openvpn:servers:{{ instance }}:server_csr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The server :ref:`glossary-CSR`.

Default: generate automatically (``None``).

.. _pillar-openvpn-servers-instance-server_key:

openvpn:servers:{{ instance }}:server_key
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The server key.

Default: generate automatically (``None``).

.. _pillar-openvpn-servers-instance-server_crt:

openvpn:servers:{{ instance }}:server_crt
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The server certificate.

Default: generate automatically (``None``).

.. _pillar-openvpn-servers-instance-topology:

openvpn:servers:{{ instance }}:topology
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Which topology will be used for this instance.

Available options:

* ``subnet``: The recommended topology for modern servers. Note that this is
  not the current default. Addressing is done by IP & netmask.
* ``net30``: This is the old topology for support with Windows clients running
  2.0.9 or older clients. This is the default as of OpenVPN 2.3, but not
  recommended for current use. Each client is allocated a virtual /30, taking 4
  IPs per client, plus 4 for the server.
* ``p2p``: This topology uses Point-to-Point networking. This is not compatible
  with Windows clients, though use with non-Windows allows use of the entire
  subnet (no "lost" IPs.)

Default: use the topology for modern servers (``subnet``).

.. _pillar-openvpn-servers-instance-mode:

openvpn:servers:{{ instance }}:mode
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Which authentication mode will be used for this instance.
Either ``static`` or ``tls``.

.. _pillar-openvpn-servers-instance-config:

openvpn:servers:{{ instance }}:config
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Map to :doc:`index` configuration options. Please consult
`OpenVPN document
<http://openvpn.net/index.php/open-source/documentation.html>`_
for more details.

Note: some keys is "reserved" or "blocked" when provide through this salt
formula.

Reserved keys::

    secret, user, group, syslog, writepid, port, ifconfig, remote

Blocked keys::

    log, log-append

.. _pillar-openvpn-servers-instance-secret:

openvpn:servers:{{ instance }}:secret
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Secret key used for this tunnel.

.. _pillar-openvpn-servers-instance-peers-peername:

openvpn:servers:{{ instance }}:peers:{{ peername }}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Dictionnary of peers.

.. _pillar-openvpn-servers-instance-peers-peername-vpn_address:

openvpn:servers:{{ instance }}:peers:{{ peername }}:vpn_address
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Address of :ref:`glossary-VPN` endpoint.

.. _pillar-openvpn-servers-instance-peers-peername-address:

openvpn:servers:{{ instance }}:peers:{{ peername }}:address
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Address of remote peer.

.. _pillar-openvpn-servers-instance-peers-peername-port:

openvpn:servers:{{ instance }}:peers:{{ peername }}:port
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:ref:`glossary-TCP`/:ref:`glossary-UDP` port number for both local and remote.

Default: use port 1194 (``''``).

.. _pillar-openvpn-servers-instance-port:

openvpn:servers:{{ instance }}:port
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Which :ref:`glossary-TCP`/:ref:`glossary-UDP` port should this instance listen
on.

.. _pillar-openvpn-servers-instance-protocol:

openvpn:servers:{{ instance }}:protocol
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:ref:`glossary-TCP` or :ref:`glossary-UDP` server.

Choices:

* udp (default)
* udp6
* tcp
* tcp6

.. _pillar-openvpn-servers-instance-device:

openvpn:servers:{{ instance }}:device
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``dev tun`` will create a routed IP tunnel,
``dev tap`` will create an ethernet tunnel.

.. _pillar-openvpn-servers-instance-server:

openvpn:servers:{{ instance }}:server
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Configure server mode and supply a :ref:`glossary-VPN` subnet for :doc:`index`
to draw client addresses from.

.. _pillar-openvpn-servers-instance-server-ipv6:

openvpn:servers:{{ instance }}:server-ipv6
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Same as :ref:`pillar-openvpn-servers-instance-server` but for
:ref:`glossary-IPv6`.

.. _pillar-openvpn-servers-instance-ifconfig-pool:

openvpn:servers:{{ instance }}:ifconfig-pool
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A pool of subnets to be dynamically allocated to connecting clients. Data
formed as ``<start-IP> <end-IP>``.

.. note::

   Static :ref:`glossary-IP` addresses should be assigned outside of this pool.

.. _pillar-openvpn-servers-instance-ifconfig-ipv6-pool:

openvpn:servers:{{ instance }}:ifconfig-ipv6-pool
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Same as :ref:`pillar-openvpn-servers-instance-ifconfig-pool` but for
:ref:`glossary-IPv6`.

.. _pillar-openvpn-servers-instance-extra_configs:

openvpn:servers:{{ instance }}:extra_configs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

List here all extra configs.

If your :doc:`index` use ``push-route`` option, the :doc:`/sysctl/doc/index`
formula need to be included and at least the following pillar key defined
for :ref:`pillar-sysctl`::

  sysctl:
    net.ipv4.ip_forward: 1

.. _pillar-openvpn-servers-instance-clients:

openvpn:servers:{{ instance }}:clients
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A list of client's name. The element can be a single value that will be
appended to the ``{{ instance }}_`` to become a
`common name <http://info.ssl.com/article.aspx?id=10048>`_ when generating
client certificates.

If the element is a dictionary, then the value is the static :ref:`glossary-IP`
that will be allocated to that client based on its common name.
