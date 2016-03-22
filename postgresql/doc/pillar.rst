Pillar
======

For more detail information and concepts explanation, see
http://www.postgresql.org/docs/9.1/static/runtime-config-connection.html. Most
of bellow explanation copied from that source.

.. include:: /doc/include/add_pillar.inc

- :doc:`/apt/doc/index` :doc:`/apt/doc/pillar`
- :doc:`/rsyslog/doc/index` :doc:`/rsyslog/doc/pillar`
- if ``postgresql:ssl`` is defined :doc:`/ssl/doc/index` :doc:`/ssl/doc/pillar`

Example::

  postgresql:
    listen_addresses: '*'
    replication:
      hot_standby: True
       master: 10.0.0.2
       standby:
         - 10.0.0.5
         - 10.0.0.6
    monitoring:
      password: mypassword
    local_trust:
      backend: jenkins

Optional
--------

.. _pillar-postgresql-local_trust:

postgresql:local_trust
~~~~~~~~~~~~~~~~~~~~~~

Dictionary of trusted connections to local host. Each pair in form of::

  dbname: username

Default: trust no local host connection (``{}``).

.. _pillar-postgresql-listen_addresses:

postgresql:listen_addresses
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Specifies the :ref:`glossary-TCP`/IP address(es) on which the server is to
listen for
connections from client applications. The value takes the form of a
comma-separated list of host names and/or numeric IP addresses. The special
entry ``*`` corresponds to all available IP interfaces. The entry ``0.0.0.0``
allows
listening for all IPv4 addresses and ``::`` allows listening for all IPv6
addresses. If the list is empty, the server does not listen on any IP interface
at all, in which case only Unix-domain sockets can be used to connect to it.

Default: allows only local :ref:`glossary-TCP`/IP "loopback" connections to be
made (``['127.0.0.1', '::1']``).

.. _pillar-postgresql-listen_port:

postgresql:listen_port
~~~~~~~~~~~~~~~~~~~~~~

The :ref:`glossary-TCP` port the server listens on.
Note that the same port number is used for all IP addresses the server listens
on.

Default: :doc:`index` default value (``5432``).

.. _pillar-postgresql-work_mem:

postgresql:work_mem
~~~~~~~~~~~~~~~~~~~

Specifies the amount of memory to be used by internal sort operations and hash
tables before writing to temporary disk files. Unit: MB.

Default: 1MB (``1``).

.. _pillar-postgresql-shared_buffers:

postgresql:shared_buffers
~~~~~~~~~~~~~~~~~~~~~~~~~

Sets the amount of memory the database server uses for shared memory buffers.

Default: :doc:`index` default value (``24MB``).

.. _pillar-postgresql-temp_buffers:

postgresql:temp_buffers
~~~~~~~~~~~~~~~~~~~~~~~

Sets the maximum number of temporary buffers used by each database session.

Default: :doc:`index` default value (``8MB``).

.. _pillar-postgresql-max_connections:

postgresql:max_connections
~~~~~~~~~~~~~~~~~~~~~~~~~~

Determines the maximum number of concurrent connections to the database server.

Default: allows (``100``) connections at the same time.

.. _pillar-postgresql-monitoring-password:

postgresql:monitoring:password
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Password for monitoring user.

Default: auto-generate by Salt (``None``).

.. _pillar-postgresql-ssl:

postgresql:ssl
~~~~~~~~~~~~~~

Name of :doc:`/ssl/doc/index` key used for encrypted :doc:`index` connection.

Default: does not use :doc:`/ssl/doc/index`/TLS (``False``).

.. _pillar-postgresql-log_slow_query:

postgresql:log_slow_query
~~~~~~~~~~~~~~~~~~~~~~~~~

Logging for query statement.

``-1`` is disabled.

``0`` logs all statements.

> ``0`` logs only statements running at least this number of milliseconds.

Default: :doc:`index` default value (``-1``).

Conditional
-----------

.. _pillar-postgresql-replication:

postgresql:replication
~~~~~~~~~~~~~~~~~~~~~~

Keys prefix with ``postgresql:replication:`` are only used for cluster setup.
For more details on :doc:`index` replication setting up, consult
http://www.postgresql.org/docs/9.1/static/high-availability.html.
This formula uses
http://www.postgresql.org/docs/9.1/static/continuous-archiving.html
method for replication and high availability.

.. _pillar-postgresql-replication-master:

postgresql:replication:master
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

IP address of `master server
<http://www.postgresql.org/docs/9.1/static/high-availability.html>`_.

This key is mandatory in setting up a cluster.

.. _pillar-postgresql-replication-username:

postgresql:replication:username
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:doc:`index` username used for replication.

Default: ``replication_agent``.

.. _pillar-postgresql-replication-hot_standby:

postgresql:replication:hot_standby
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Run standby servers in
`hot standby mode
<http://www.postgresql.org/docs/9.1/static/hot-standby.html>`_

Default: run standby servers in hot standby mode (``True``).

.. _pillar-postgresql-replication-standby:

postgresql:replication:standby
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

List of addresses of standby nodes in cluster.

Default: no standby node (``[]``).

postgresql:remote
~~~~~~~~~~~~~~~~~

List of :ref:`glossary-CIDR` format networks that are allowed to connect to
:doc:`index` remotely.

Default: allow no remote connection (``[]``).
