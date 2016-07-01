Pillar
======

.. include:: /doc/include/add_pillar.inc

Mandatory
---------

webdav:server_name
~~~~~~~~~~~~~~~~~~

Domain to access :doc:`index`.

Optional
--------

Example::

  webdav:
    ssl: example_com

webdav:ssl
~~~~~~~~~~

Default: ``False``.

webdav:users
~~~~~~~~~~~~

Map of username and SHA512/256 hash of corresponding password to access
:doc:`index`.

Default: allowing no users (``{}``).

webdav:logging_level
~~~~~~~~~~~~~~~~~~~~

Default: (``warning``).
