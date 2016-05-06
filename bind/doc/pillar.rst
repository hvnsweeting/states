Pillar
======

.. include:: /doc/include/add_pillar.inc

.. note::

  all ``TTL`` in this document has different meaning to :ref:`glossary-ttl`,
  TTL here which is the time to live of the :ref:`glossary-RR`.  This field is
  a 32 bit integer in units of seconds, an is primarily used by resolvers when
  they cache :ref:`glossary-RR` . The TTL describes how long a
  :ref:`glossary-RR` can be cached before it should be discarded.
  See http://www.ietf.org/rfc/rfc1035.txt for more details.

Mandatory
---------

Example::

  bind:
    allowed_subnets:
      - any

.. _pillar-bind-allowed_subnets:

bind:allowed_subnets
~~~~~~~~~~~~~~~~~~~~

List of IP addresses which are allowed to issue query to the server.
Special keyword ``salt_mine`` can be mixed with list of subnets. It will
automatically add all public IPs of all hosts in :doc:`/salt/master/doc/index`
mine.

.. note::

   In the above example, ``any`` means that all hosts are allowed to make
   queries.

Optional
--------

.. _pillar-bind-public_ip:

bind:public_ip
~~~~~~~~~~~~~~

Specify public IP of this host. It's sometimes necessary when the public IP
does not attach directly to the host's interface.

Default: use first IP from eth0 interface on the host. (``None``)

.. _pillar-bind-forwarders:

bind:forwarders
~~~~~~~~~~~~~~~

Default: does not use forwarder (``[]``).

.. _pillar-bind-tsig_key:

bind:tsig_key
~~~~~~~~~~~~~

HMAC-MD5 TSIG key created by dnssec-keygen tool. Used for updating DNS
information dynamically from a remote client.

Default: does not provide any key, disable dynamic update (``None``).

.. _pillar-bind-zones:

bind:zones
~~~~~~~~~~

Default: setting no custom zone (``{}``).

Conditional
-----------

.. _pillar-bind-disable_recursion:

bind:disable_recursion
~~~~~~~~~~~~~~~~~~~~~~

Whether to disable recursion feature on an authoritative server, which
has :ref:`pillar-bind-zones` defined.

.. note::

  A public :doc:`index` server, which sets :ref:`pillar-bind-allowed_subnets`
  to [`any`] and expose to Internet must set this value to ``True`` to not to
  be an open resolver. See `this <http://serverfault.com/questions/573465/
  what-is-an-open-dns-resolver-and-how-can-i-protect-my-server-from-
  being-misused>`_ for more detail.

Default: disable (``True``).

.. _pillar-bind-zones-{{ zone_name }}:

bind:zones:{{ zone_name }}
~~~~~~~~~~~~~~~~~~~~~~~~~~

Name of the zone that this server will be authoritative server for.

.. _pillar-bind-zones-{{ zone_name }}-file:

bind:zones:{{ zone_name }}:file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Filename which will contain data for the zone.

.. _pillar-bind-zones-{{ zone_name }}-forwarders:

bind:zones:{{ zone_name }}:forwarders
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

List of forwarders that this server will forward the queries that it cannot
satisfy from its cache to another caching name server.

Default: no forward queries (``[]``).

.. _pillar-bind-zones-{{ zone_name }}-allow_dynamic:

bind:zones:{{ zone_name }}:allow_dynamic
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Allowing dynamic update for the zone.

Default: disable (``False``).

.. _pillar-bind-zones-{{ zone_name }}-masters:

bind:zones:{{ zone_name }}:masters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

IP addresses of master server, if this server serves as a slave for this zone.

Default: this will act as a master server (``[]``).

.. _pillar-bind-zones-{{ zone_name }}-ttl:

bind:zones:{{ zone_name }}:ttl
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Default TTL for all resource records in zone ``{{ zone_name }}`` in unit of
seconds.

Default: ``2560`` seconds.

.. _pillar-bind-zones-{{ zone_name }}-admin_email:

bind:zones:{{ zone_name }}:admin_email
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Email of administrator of this zone.

.. _pillar-bind-zones-{{ zone_name }}-serial:

bind:zones:{{ zone_name }}:serial
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Version number of this zone.

.. note::

  This number MUST be increased everywhen there is a change in the
  {{ zone_name }}. When :ref:`pillar-bind-zones-{{ zone_name }}-allow_dynamic`
  is `True`, the number will be increased automatically after each change
  by dynamic DNS.

Default: ``1``.

.. _pillar-bind-zones-{{ zone_name }}-refresh:

bind:zones:{{ zone_name }}:refresh
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Time interval before the zone should be refreshed in units of seconds.

Default: ``16384`` seconds.

.. _pillar-bind-zones-{{ zone_name }}-retry:

bind:zones:{{ zone_name }}:retry
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Time interval that should elapse before a failed refresh should be retried
in units of seconds.

Default: ``2048`` seconds.

.. _pillar-bind-zones-{{ zone_name }}-expire:

bind:zones:{{ zone_name }}:expire
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Specifies the upper limit on the time interval that can
elapse before the zone is no longer authoritative.

Default: ``1048576`` seconds.

.. _pillar-bind-zones-{{ zone_name }}-minimum:

bind:zones:{{ zone_name }}:minimum
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Minimum TTL field that should be exported with any :ref:`glossary-RR`
 from this zone.

Default: ``2560`` seconds.

.. _pillar-bind-zones-{{ zone_name }}-slaves:

bind:zones:{{ zone_name }}:slaves
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

List of IP of slaves servers of this zone. Order of elements matter, as it
will be assigned as ns2, ns3, etc...

Default: No slave server ``[]``.

.. _pillar-bind-zones-{{ zone_name }}-resource_records:

bind:zones:{{ zone_name }}:resource_records
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

List of resource records. Each resource record represented by a string
in format of ``<name> <ttl> <type> <rdata>``. ``ttl`` is optional.

Default: Set no record (``[]``).
