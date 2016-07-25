Monitor
=======

.. |deployment| replace:: salt.api

.. warning::

   In this document, when refer to a pillar key ``pillar_prefix``
   means ``salt_api``.

Mandatory
---------

.. _monitor-salt_api_procs:

salt_api_procs
~~~~~~~~~~~~~~

:doc:`/salt/api/doc/index` daemon provides RESTFUL API for
:doc:`/salt/master/doc/index`.

.. include:: /nrpe/doc/check_procs.inc

.. include:: /nginx/doc/monitor.inc

.. _monitor-salt_api_port:

salt_api_port
~~~~~~~~~~~~~

Check if the port `glossary-TCP` ``8000`` which
:doc:`/salt/api/doc/index` runs on is open.

Optional
--------

.. include:: /nginx/doc/monitor_ssl.inc

Only use if an :ref:`glossary-IPv6` address is present.

.. include:: /nginx/doc/monitor_ipv6.inc
