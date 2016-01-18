Monitor
=======

Mandatory
---------

.. |deployment| replace:: discourse

.. warning::

   In this document, when refer to a pillar key ``pillar_prefix``
   means ``discourse``.

.. _monitor-discourse_sidekiq_procs:

discourse_sidekiq_procs
~~~~~~~~~~~~~~~~~~~~~~~

.. include:: /nrpe/doc/check_procs.inc

Monitor :doc:`index` `Sidekiq <http://sidekiq.org/>`_
process.

.. include:: /nginx/doc/monitor.inc

.. _monitor-discourse_postgresql:

discourse_postgresql
~~~~~~~~~~~~~~~~~~~~

Check :doc:`/postgresql/doc/index` connection.

Critical: if unable to connect.

.. _monitor-discourse_postgresql_encoding:

discourse_postgresql_encoding
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Check if :doc:`/postgresql/doc/index` database encoding is UTF8.

.. _monitor-discourse_postgresql_not_empty:

discourse_postgresql_not_empty
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Check if :doc:`/postgresql/doc/index` database is not empty.

.. _monitor-discourse-unicorn-procs:

discourse_unicorn_procs
~~~~~~~~~~~~~~~~~~~~~~~

.. include:: /nrpe/doc/check_procs.inc

.. _monitor-discourse-unicorn-port:

Optional
--------

Only use if :ref:`pillar-discourse-ssl` is turned defined.

.. include:: /nginx/doc/monitor_ssl.inc

Only use if an :ref:`glossary-IPv6` address is present.

.. include:: /nginx/doc/monitor_ipv6.inc
