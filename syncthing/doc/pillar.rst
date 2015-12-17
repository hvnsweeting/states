Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/apt/doc/index` :doc:`/apt/doc/pillar`
- :doc:`/nginx/doc/index` :doc:`/nginx/doc/pillar`

Mandatory
---------

Example::

  syncthing:
    hostnames:
      - syncthing.example.com
    password: mypassword

.. _pillar-syncthing-password:

syncthing:password
~~~~~~~~~~~~~~~~~~

Password for :doc:`index` ``admin`` account.

.. _pillar-syncthing-device_id:

syncthing:device_id
~~~~~~~~~~~~~~~~~~~

Device ID of :doc:`index` instance. For more information, consult `official docs
<http://docs.syncthing.net/dev/device-ids.html>`_. Use generate.sh script in
:doc:`index` formula to create pillar for new installation.

.. _pillar-syncthing-cert:

syncthing:cert
~~~~~~~~~~~~~~

SSL cerfiticate of :doc:`index` instance. Use generate.sh script in :doc:`index`
formula to create pillar for new installation.

.. _pillar-syncthing-key:

syncthing:key
~~~~~~~~~~~~~

SSL key of :doc:`index` instance. Use generate.sh script in :doc:`index` formula
to create pillar for new installation.

Optional
--------

Example::

  syncthing:
    ssl: syncthing.example.com
    ssl_redirect: True

.. _pillar-syncthing-ssl:

syncthing:ssl
~~~~~~~~~~~~~

.. include:: /nginx/doc/ssl.inc

.. _pillar-syncthing-ssl_redirect:

syncthing:ssl_redirect
~~~~~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/ssl_redirect.inc

.. _pillar-syncthing-folders:

syncthing:folders
~~~~~~~~~~~~~~~~~

Folders to share with other devices.

Example::

  syncthing:
    folders:
      test:
        path: /usr/local/test # optional, default to /var/lib/syncthing/test
        readonly: True # optional, default to False
        ignore_delete: True # optional, default to False
        devices:
          - device-1
          - device-2

Devices attribute must be a list of devices define in
:ref:`pillar-syncthing-devices`.

`ignore_delete <http://docs.syncthing.net/advanced/folder-ignoredelete.html>`_
causes the shared directory to ignore all delete instructions. This is an
advance feature, be careful when using it.

:doc:`index` formula implicitly defines a folder with following config::

  syncthing:
    folders:
      default:
        path: /var/lib/syncthing/Sync
        devices:
          - {{ minion_id }}

Default: share no folder (``{}``).

.. _pillar-syncthing-devices:

syncthing:devices
~~~~~~~~~~~~~~~~~

Known devices to share resources with.

Example::

  syncthing:
    devices:
      {{ grains['id'] }}:
        id: MFZWI3D-BONSGYC-YLTMRWG-C43ENR5-QXGZDMM-FZWI3DP-BONSGYY-LTMRWAD
        compression: always # optional, default to "metadata"
        introducer: True # optional, default to False
        addresses:  # optional, default is pick from mine
          - 192.168.1.100

Data formed as a dictionary with key must be match the minion id and value is
another dictionary, details as above.

:doc:`index` formula implicitly defines a device with following config::

  syncthing:
    devices:
      {{ grains["id"] }}:
        id: {{ own syncthing id }}

Default: share resources with no device (``{}``).

.. _pillar-syncthing-hostnames:

syncthing:hostnames
~~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/hostnames.inc

Default: don't use web interface (``[]``).
