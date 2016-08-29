Monitor
=======

Mandatory
---------


.. |deployment| replace:: webdav

.. warning::

   In this document, when refer to a pillar key ``pillar_prefix``
   means ``webdav``.

.. include:: /backup/doc/monitor.inc

.. _monitor-webdav_procs:

webdav_procs
~~~~~~~~~~~~

:doc:`/webdav/doc/index` daemon process.

.. include:: /nrpe/doc/check_procs.inc

.. _monitor-webdav_port:

webdav_port
~~~~~~~~~~~

:doc:`/webdav/doc/index` :ref:`glossary-daemon`
:ref:`glossary-HTTP` Port is listening.

.. _monitor-webdav_https:

webdav_https
~~~~~~~~~~~~

:doc:`/webdav/doc/index` :ref:`glossary-daemon`
:ref:`glossary-HTTPS` port works properly.
