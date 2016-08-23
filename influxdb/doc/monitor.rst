Monitor
=======

Mandatory
---------

.. |deployment| replace:: influxdb

.. warning::

   In this document, when refer to a pillar key ``pillar_prefix``
   means ``influxdb``.

.. _monitor-influxdb_procs:

influxdb_procs
~~~~~~~~~~~~~~

.. include:: /nrpe/doc/check_procs.inc

.. _monitor-influxdb_admin_port:

influxdb_admin_port
~~~~~~~~~~~~~~~~~~~

:doc:`index` admin interface port :ref:`glossary-TCP` ``8083`` is listening on
:ref:`glossary-localhost`.

.. _monitor-influxdb_admin_port_ipv6:

influxdb_admin_port_ipv6
~~~~~~~~~~~~~~~~~~~~~~~~

Same as :ref:`monitor-influxdb_admin_port` but for :ref:`glossary-IPv6`.

.. _monitor-influxdb_data_port:

influxdb_data_port
~~~~~~~~~~~~~~~~~~

:doc:`index` data port :ref:`glossary-TCP` ``8086`` is listening on
:ref:`glossary-localhost`.

.. _monitor-influxdb_data_port_ipv6:

influxdb_data_port_ipv6
~~~~~~~~~~~~~~~~~~~~~~~

Same as :ref:`monitor-influxdb_data_port` but for :ref:`glossary-IPv6`.

.. _monitor-influxdb_meta_port:

influxdb_meta_port
~~~~~~~~~~~~~~~~~~

:doc:`index` meta port :ref:`glossary-TCP` ``8088`` is listening on
:ref:`glossary-localhost`.

.. _monitor-influxdb_meta_port_ipv6:

influxdb_meta_port_ipv6
~~~~~~~~~~~~~~~~~~~~~~~

Same as :ref:`monitor-influxdb_meta_port` but for :ref:`glossary-IPv6`.

.. include:: /backup/doc/monitor.inc

.. include:: /backup/doc/monitor_procs.inc
