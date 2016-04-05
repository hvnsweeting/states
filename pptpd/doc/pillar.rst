Pillar
======

sysctl
------

:doc:`/sysctl/doc/index` :doc:`/sysctl/doc/pillar` need to have at least the
following::

  sysctl:
    net.ipv4.ip_forward: 1

ppp
---

:doc:`/pppd/doc/index` :doc:`/pppd/doc/pillar` need to have at least the
following::

  pppd:
    instances:
      pptpd:
        ... values ...

Mandatory
---------

.. _pillar-pptpd-local_ips:

pptpd:local_ips
~~~~~~~~~~~~~~~

Specifies the list of local IP address ranges.

Example::

  pptpd:
    local_ips:
      - 192.168.0.234
      - 192.168.0.245-249
      - 192.168.0.254

If more IP addresses are given than the value of connections, it will start at
the beginning of the list and go until it gets connections IPs.
Others will be ignored.

Any addresses work as long as the local machine takes care of the routing.

.. warning::

  No shortcuts in ranges! ie. ``234-8`` does not mean ``234`` to ``238``,
  use ``234-238`` for this.

If a single local IP is given, that's ok - all local IPs will
be set to the given one. At least one remote IP for each simultaneous client
must be defined.

.. _pillar-pptpd-remote_ips:

pptpd:remote_ips
~~~~~~~~~~~~~~~~

Specifies the list of remote IP address ranges.

Same format as :ref:`pillar-pptpd-local_ips`.

Optional
--------

.. _pillar-pptpd-logwtmp:

pptpd:logwtmp
~~~~~~~~~~~~~

Record client connections and disconnections or not.

Default: no logging (``False``).

.. _pillar-pptpd-debug:

pptpd:debug
~~~~~~~~~~~

Turns on (more) debugging to syslog.

Default: no debugging (``False``).

.. _pillar-pptpd-max_connections:

pptpd:max_connections
~~~~~~~~~~~~~~~~~~~~~

Limits the number of client connections that may be accepted.

If :doc:`index` is allocating IP addresses then the number of connections is
also limited by the :ref:`pillar-pptpd-remote_ips` value.

Default: ``100`` connections.
