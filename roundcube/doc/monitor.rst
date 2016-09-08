Monitor
=======

Mandatory
---------

.. |deployment| replace:: roundcube

.. warning::

   In this document, when refer to a pillar key ``pillar_prefix``
   means ``roundcube``.

.. include:: /postgresql/doc/monitor.inc

.. include:: /nginx/doc/monitor.inc

.. include:: /backup/doc/monitor_postgres_procs.inc

.. include:: /backup/doc/monitor.inc


Optional
--------

Only use if :ref:`pillar-roundcube-ssl` is turned on.

.. include:: /nginx/doc/monitor_ssl.inc

Only use if an :ref:`glossary-IPv6` address is present.

.. include:: /nginx/doc/monitor_ipv6.inc
