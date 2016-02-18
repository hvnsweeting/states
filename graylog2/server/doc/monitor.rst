Monitor
=======

Mandatory
---------

.. _monitor-graylog2_server-es_cluster:

graylog2_server-es_cluster
~~~~~~~~~~~~~~~~~~~~~~~~~~

Check :doc:`/elasticsearch/doc/index` cluster status.

.. _monitor-graylog2_server~es_port_transport:

graylog2_server-es_port_transport
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Check :doc:`/elasticsearch/doc/index` transport port :ref:`glossary-TCP`
connection.

.. _monitor-graylog2_server~es_port_transport_ipv6:

graylog2_server-es_port_transport_ipv6
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Check :doc:`/elasticsearch/doc/index` transport port :ref:`glossary-TCP`
connection through IPv6.

.. _monitor-graylog2_procs:

graylog2_procs
~~~~~~~~~~~~~~

.. include:: /nrpe/doc/check_procs.inc

.. _monitor-graylog2_api_port:

graylog2_api_port
~~~~~~~~~~~~~~~~~

Monitor :doc:`/graylog2/doc/index` API port :ref:`glossary-TCP` ``12900``.

.. _monitor-graylog2_api:

graylog2_api
~~~~~~~~~~~~

Monitor :doc:`/graylog2/doc/index` API :ref:`glossary-HTTP` :ref:`glossary-TCP` ``12900``.

Expect return code: '401 Unauthorized' (:doc:`/graylog2/doc/index` API
require authentication)

.. _monitor-graylog2_incoming_logs:

graylog2_incoming_logs
~~~~~~~~~~~~~~~~~~~~~~

Monitor incoming logs rate.

Critical: ``0`` msg/seccond

graylog2_input_gelf
~~~~~~~~~~~~~~~~~~~

Monitor :doc:`/graylog2/doc/index` `GELF <http://www.graylog2.org/gelf>`_ input
port ``12201/udp``.

graylog2_input_syslog
~~~~~~~~~~~~~~~~~~~~~

Monitor :doc:`/graylog2/doc/index` syslog input port ``1514/udp``.

graylog2_backup_mongodb_procs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

At most one process backup for :doc:`/graylog2/doc/index`
:doc:`/mongodb/doc/index` is running.

graylog2_backup
~~~~~~~~~~~~~~~

Monitor :doc:`/graylog2/doc/index` backup age and size.
