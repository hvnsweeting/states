Pillar
======

.. include:: /doc/include/pillar.inc

Mandatory
---------

Example::

  quagga:
    password: edcrfv
    enable_password: tgbyhn
    zebra:
      lo:
        address: 10.255.250.1/32
    ospfd:
      networks:
        - 192.168.1.0/24

.. _pillar-quagga-password:

quagga:password
~~~~~~~~~~~~~~~

The password to connect to the :doc:`index` daemons.

.. _pillar-quagga-enable_password:

quagga:enable_password
~~~~~~~~~~~~~~~~~~~~~~

The enable password to access to various privilege levels of :doc:`index`
daemons.

.. _pillar-quagga-zebra-lo-address:

quagga:zebra:lo:address
~~~~~~~~~~~~~~~~~~~~~~~

Which address will be advertised via loopback interface.

.. _pillar-quagga-ospfd-networks:

quagga:ospfd:networks
~~~~~~~~~~~~~~~~~~~~~

List of networks for router ospf.

Optional
--------

Example::

  quagga:
    upgrade: True
    zebra:
      password: qazwsx
      enable_password: tgbyhn
    ospfd:
      interfaces:
        tap1:
          priority: 100
      password: qazwsx
      enable_password: tgbyhn
    ospf6d:
      password: qazwsx
      enable_password: tgbyhn
      router_id: 255.1.1.1

.. _pillar-quagga-upgrade:

quagga:upgrade
~~~~~~~~~~~~~~

Whether to upgrade quagga automatically or not.

Default: do not upgrade as it can cause loss of connectivity (``False``).

.. _pillar-quagga-{{ daemon }}-password:

quagga:{{ daemon }}:password
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The password to connect to the {{ daemon }} daemon.

Default: use the value of :ref:`pillar-quagga-password` (``False``).

.. _pillar-quagga-{{ daemon }}-enable_password:

quagga:{{ daemon }}:enable_password
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The enable password to access to various privilege levels of {{ daemon }} daemon.

Default: use the value of :ref:`pillar-quagga-enable_password` (``False``).

.. _pillar-quagga-ospfd-interfaces:

quagga:ospfd:interfaces
~~~~~~~~~~~~~~~~~~~~~~~

A dictionary with key is the OSPF interface and value is another dictionary of
properties which will be set on that interface. Details as belows.

Default: no additional interface (``{}``).

.. _pillar-quagga-ospf6d-router_id:

quagga:ospf6d:router_id
~~~~~~~~~~~~~~~~~~~~~~~

The router-ID of the OSPF6D process. The router-ID may be an IP address
of the router, but need not be - it can be any arbitrary 32bit number. However
it MUST be unique within the entire OSPF domain to the OSPF speaker - bad
things will happen if multiple OSPF speakers are configured with the same
router-ID! If one is not specified then ``ospf6d`` will obtain a router-ID
automatically from ``zebra``.

Default: use the :ref:`glossary-IPv4` address (``False``).

Conditional
-----------

.. _pillar-quagga-ospfd-interfaces-interface-priority:

quagga:ospfd:interfaces:{{ interface }}:priority
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Set RouterPriority integer value in range 0-255. The router with the highest
priority will be more eligible to become Designated Router. Setting the value
to 0, makes the router ineligible to become Designated Router.

Default: ``1``.
