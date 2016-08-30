Pillar
======

.. include:: /doc/include/pillar.inc

- :doc:`/git/doc/index` :doc:`/git/doc/pillar`
- :doc:`/nginx/doc/index` :doc:`/nginx/doc/pillar`
- :doc:`/pip/doc/index` :doc:`/pip/doc/pillar`
- :doc:`/rsyslog/doc/index` :doc:`/rsyslog/doc/pillar`
- :doc:`/salt/master/doc/index` :doc:`/salt/master/doc/pillar`

Mandatory
---------

.. _pillar-salt_api-hostnames:

salt_api:hostnames
~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/hostnames.inc

.. _pillar-salt_api-allow_ips:

salt_api:allow_ips
~~~~~~~~~~~~~~~~~~

List of IPs those are allowed to access :doc:`index`.
As :doc:`index` is a security sensitive service. It should not expose
on internet.

Optional
--------

.. _pillar-salt_api-ssl:

salt_api:ssl
~~~~~~~~~~~~

.. include:: /nginx/doc/ssl.inc

.. _pillar-salt_api-ssl_redirect:

salt_api:ssl_redirect
~~~~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/ssl_redirect.inc

.. _pillar-salt_api-external_auth:

salt_api:external_auth
~~~~~~~~~~~~~~~~~~~~~~

Example::

     external_auth:
     pam:
      test:
        password: pass
        acl:
          '*':
            - '@jobs'
            - .*

Dict of users used to authenticate against for run :doc:`/salt/doc/index`
modules. Possible ``authenticate_system`` are: ``pam`` or
``ldap``. See http://docs.saltstack.com/en/latest/topics/eauth/index.html for
more detail.

Default: ``{}``
