Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/ssh/client/doc/index` :doc:`/ssh/client/doc/pillar`

Mandatory
---------

Example::

  backup_server:
    address: 192.168.1.1
    port: 22
    subdir: common_backup

.. _pillar-backup_server-address:

backup_server:address
~~~~~~~~~~~~~~~~~~~~~

IP/Hostname of :doc:`/backup/server/doc/index`.

.. note::

  this address must be configured as a known host in
  :ref:`pillar-ssh-hosts`

Optional
--------

.. _pillar-backup_server-subdir:

backup_server:subdir
~~~~~~~~~~~~~~~~~~~~

Sub-directory of ``/var/lib/backup`` to backup file to. This uses
:doc:`/salt/minion/doc/index`
IDs of :doc:`/backup/client/doc/index` as default value. With this value, each
:doc:`/salt/minion/doc/index` will backup files to a separate directory under
``/var/lib/backup``.

Default: use :doc:`/salt/minion/doc/index` ID (``False``).

.. _pillar-backup_server-port:

backup_server:port
~~~~~~~~~~~~~~~~~~

SSH port to copy file through.

Default: (``22``).
