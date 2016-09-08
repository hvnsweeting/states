Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/nginx/doc/index` :doc:`/nginx/doc/pillar`

Mandatory
---------

Example::

  roundcube:
    hostnames:
      - mail.example.com

.. _pillar-roundcube-hostnames:

roundcube:hostnames
~~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/hostnames.inc

Optional
--------

.. _pillar-roundcube-ssl:

roundcube:ssl
~~~~~~~~~~~~~

.. include:: /nginx/doc/ssl.inc

.. _pillar-roundcube-ssl_redirect:

roundcube:ssl_redirect
~~~~~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/ssl_redirect.inc

.. _pillar-roundcube-db-username:

roundcube:db:username
~~~~~~~~~~~~~~~~~~~~~

.. include:: /postgresql/doc/username.inc

Default: ``roundcube``.

.. _pillar-roundcube-db-name:

roundcube:db:name
~~~~~~~~~~~~~~~~~

.. include:: /postgresql/doc/name.inc

Default: ``roundcube``.

.. _pillar-roundcube-db-password:

roundcube:db:password
~~~~~~~~~~~~~~~~~~~~~

.. include:: /postgresql/doc/password.inc

.. _pillar-roundcube-imap-server:

roundcube:imap:server
~~~~~~~~~~~~~~~~~~~~~

IP or hostname of :doc:`/dovecot/doc/index`
`IMAP <https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol>`_
server to connect to.

Default: localhost ``127.0.0.1``.

.. _pillar-roundcube-imap-ssl:

roundcube:imap:ssl
~~~~~~~~~~~~~~~~~~

If connect to IMAP server using `SSL </ssl/doc/index>`.

Default: ``False``.

.. |deployment| replace:: roundcube

.. _pillar-roundcube-ldap-suffix:

roundcube:ldap:suffix
~~~~~~~~~~~~~~~~~~~~~

LDAP suffix used to config :doc:`index`
supports changing password (LDAP password) of user through :doc:`index` WebUI.

Default: ``False`` - means use value provided for ``ldap:suffix`` pillar key.

.. _pillar-roundcube-ldap-ssl:

roundcube:ldap:ssl
~~~~~~~~~~~~~~~~~~

Whether to use STARTTLS for :doc:`/openldap/doc/index` connection when changing
password or not.

Default: ``False`` - means use value provided for ``ldap:ssl``
:doc:`/openldap/doc/pillar` key.
