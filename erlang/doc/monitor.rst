Monitor
=======

Mandatory
---------

erlang_dummy
~~~~~~~~~~~~

Dummy check.

Optional
--------

.. |deployment| replace:: erlang

.. warning::

   In this document, when refer to a pillar key ``pillar_prefix``
   means ``erlang``.

erlang_procs
~~~~~~~~~~~~

:doc:`index` Port Mapper Daemon.

.. include:: /nrpe/doc/check_procs.inc

erlang_port
~~~~~~~~~~~

Check if :doc:`index` Port Mapper service is listening on address and
:ref:`glossary-TCP` port 4369
