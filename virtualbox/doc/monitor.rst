Monitor
=======

Mandatory
---------

.. |deployment| replace:: virtualbox

.. _monitor-virtualbox_kernel_modules:

virtualbox_kernel_modules
~~~~~~~~~~~~~~~~~~~~~~~~~

Whether the :doc:`index` kernel modules are loaded or not.

.. _monitor-virtualbox_procs:

virtualbox_procs
~~~~~~~~~~~~~~~~

.. include:: /nrpe/doc/check_procs.inc

Expected status: there is only one process with command line name
``/usr/lib/virtualbox/VBoxSVC`` is running as ``virtualbox`` user.
