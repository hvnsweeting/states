Monitor
=======

Mandatory
---------

.. |deployment| replace:: ospfd

.. _monitor-ospfd_procs:

ospfd_procs
~~~~~~~~~~~

.. include:: /nrpe/doc/check_procs.inc

Expected status: there is only one process with command line arguments
``/usr/lib/quagga/ospfd --daemon`` running by user ``quagga``

.. _monitor-ospfd_port:

ospfd_port
~~~~~~~~~~

Monitor :doc:`index` local port :ref:`glossary-TCP` ``2604``.

.. _monitor-ospf6d_procs:

ospf6d_procs
~~~~~~~~~~~~

.. include:: /nrpe/doc/check_procs.inc

Expected status: there is only one process with command line arguments
``/usr/lib/quagga/ospf6d --daemon`` running by user ``quagga``

.. _monitor-ospf6d_port:

ospf6d_port
~~~~~~~~~~~

Monitor :doc:`index` local port :ref:`glossary-TCP` ``2606``.

.. _monitor-zebra_procs:

zebra_procs
~~~~~~~~~~~

.. include:: /nrpe/doc/check_procs.inc

Expected status: there is only one process with command line arguments
``/usr/lib/quagga/zebra --daemon`` running by user ``quagga``

.. _monitor-zebra_port:

zebra_port
~~~~~~~~~~

Monitor :doc:`index` local port :ref:`glossary-TCP` ``2601``.
