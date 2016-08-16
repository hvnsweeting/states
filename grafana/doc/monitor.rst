Monitor
=======

Mandatory
---------


.. |deployment| replace:: grafana

.. warning::

   In this document, when refer to a pillar key ``pillar_prefix``
   means ``grafana``.

.. include:: /nginx/doc/monitor.inc

.. include:: /postgresql/doc/monitor.inc

.. include:: /backup/doc/monitor_postgres_procs.inc

.. include:: /backup/doc/monitor.inc

.. _monitor-grafana_procs:

grafana_procs
~~~~~~~~~~~~~

:doc:`/grafana/doc/index` daemon provides the whole
:doc:`/grafana/doc/index` services and Web interface.

.. include:: /nrpe/doc/check_procs.inc

.. _monitor-grafana_port:

grafana_port
~~~~~~~~~~~~

:doc:`/grafana/doc/index` :ref:`glossary-daemon` :ref:`glossary-HTTP` Port is
listening locally.

.. _monitor-grafana_http:

grafana_http
~~~~~~~~~~~~

:doc:`/grafana/doc/index` :ref:`glossary-daemon` :ref:`glossary-HTTP` port
works properly.

Optional
--------

.. include:: /nginx/doc/monitor_ssl.inc

Only use if an :ref:`glossary-IPv6` address is present.

.. include:: /nginx/doc/monitor_ipv6.inc
