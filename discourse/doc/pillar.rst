Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/apt/doc/index` :doc:`/apt/doc/pillar`


Mandatory
---------

.. _pillar-discourse-initial_admins:

discourse:initial_admins
~~~~~~~~~~~~~~~~~~~~~~~~

List of emails of administrator users.

.. _pillar-discourse-hostnames:

discourse:hostnames
~~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/hostnames.inc

Optional
--------

.. _pillar-discourse-db-password:

discourse:db:password
~~~~~~~~~~~~~~~~~~~~~

.. include:: /postgresql/doc/password.inc

.. _pillar-discourse-ssl:

discourse:ssl
~~~~~~~~~~~~~

.. include:: /nginx/doc/ssl.inc

.. _pillar-discourse-ssl_redirect:

discourse:ssl_redirect
~~~~~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/ssl_redirect.inc
