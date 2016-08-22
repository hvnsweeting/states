Global Pillar
=============

The following Pillar values are commonly used across all states.

Mandatory
---------

Example::

  message_do_not_modify: Don't edit this file manually
  smtp:
    server: smtp.example.com
    port: 25
    root: tom
    domain: example.com
    from: joe@example.com
    user: yyy
    password: xxx
    encryption: plain

.. _pillar-message_do_not_modify:

message_do_not_modify
~~~~~~~~~~~~~~~~~~~~~

Warning message to not modify file.

.. _pillar-smtp:

smtp
~~~~

Email server configuration.

See below for details on each keys.

smtp:server
~~~~~~~~~~~

The SMTP server where the mail is sent to.

smtp:port
~~~~~~~~~

SMTP server port.

smtp:root
~~~~~~~~~

The user that gets all the mails for User ID below 1000 - the system users
(normal users are given a User ID above 1000).

smtp:domain
~~~~~~~~~~~

Domain name to use.

.. _pillar-smtp-from:

smtp:from
~~~~~~~~~

The address that will appear in the "From:" field of the email.

Optional
--------

.. _pillar-smtp-user:

smtp:user
~~~~~~~~~

The username used to log into the remote SMTP server.

Default: No specify user (no authentication) (``None``).

.. _pillar-smtp-password:

smtp:password
~~~~~~~~~~~~~

Password for account login, if :ref:`pillar-smtp-user` is defined.

Default: No specify password (no authentication) (``None``).

.. _pillar-smtp-encryption:

smtp:encryption
~~~~~~~~~~~~~~~

SMTP encryption type.

Possible values: `ssl <http://en.wikipedia.org/wiki/Transport_Layer_Security>`_, `starttls <http://en.wikipedia.org/wiki/Starttls>`_, ``plain``.

Default: Sending the username and password over plaintext (``plain``)

.. _pillar-debug:

debug
~~~~~

If ``False``, drop all noisy log and extra verboseness of most log settings.

If ``True``, turn on as much debugging logging as possible.

Default: turn off debug (``False``).

.. _pillar-roles:

roles
~~~~~

List of roles that apply to a minion.
See :doc:`intro` and :doc:`usage` for details on roles.

Default: no role (``[]``).

.. _pillar-branch:

branch
~~~~~~

Which git branch to use during ``state.highstate``.

Default: ``master``.

.. _pillar-files_archive:

files_archive
~~~~~~~~~~~~~

Path to :doc:`/salt/archive/doc/index` where download most files
(archives, packages, pip) to apply states.

Default: directly get files from public Internet resources. There is no
guarantee that those hosting services will be up during file
transfer (``False``).

gem_source
~~~~~~~~~~

Gem repository to install :doc:`index`.

Default: use official repository (``"https://rubygems.org"``).

.. _pillar-sentry_dsn:

sentry_dsn
~~~~~~~~~~

`DSN <http://raven.readthedocs.org/en/latest/config/#the-sentry-dsn>`_
or API key (URL) of :doc:`/sentry/doc/index` where to send errors to.

Default: do not send errors to Sentry (``False``).

.. _pillar-graylog2_address:

graylog2_address
~~~~~~~~~~~~~~~~

IP/Hostname of centralized logging server (:doc:`/graylog2/server/doc/index`).

Default: do not send log to centralized server (``False``).

.. _pillar-graphite_address:

graphite_address
~~~~~~~~~~~~~~~~

IP/Hostname of :doc:`/carbon/doc/index` server.
This key is required if ``diamond`` integration of formulas had been included
in roles.

Default: do not send metric to :doc:`/carbon/doc/index` server (``False``).

.. _pillar-metric_server:

metric_server
~~~~~~~~~~~~~

IP/Hostname of :doc:`/influxdb/doc/index` server.

Default: do not send metric to :doc:`/influxdb/doc/index` server (``False``).

.. _pillar-shinken_pollers:

shinken_pollers
~~~~~~~~~~~~~~~

List of monitoring hosts that can perform checks on this host.
This is required if any :doc:`/nrpe/doc/index` integration of formula had been
included in roles.

Default: no monitoring host allowed to perform checks on this host (``[]``).

.. _pillar-encoding:

encoding
~~~~~~~~

Default system locale.

Default: ``en_US.UTF-8``.

.. _pillar-global_roles:

global_roles
~~~~~~~~~~~~

List of all available roles.

This key is usefull to restrict the list of available roles for an hosts.

If undefined, it's automatically built by listing sub-directories of ``/roles``.

Default: no roles (``[]``).

.. _pillar-roles_absent:

roles_absent
~~~~~~~~~~~~

If ``True``, run the ``absent`` formula of each roles that the minion is not
assigned to.

Default: ``False``.

.. _pillar-__test__:

__test__
~~~~~~~~

If ``True`` the formulas consider themselves running trough the testing
framework. That pillar key must **NEVER** be defined in non-testing pillars.

And it must **ALWAYS** be defined and set to ``True`` in testing pillars.

Not following this rule will result in lost data and broken system.

Default: run formulas in production (``False``).

.. _pillar-root_password:

root_password
~~~~~~~~~~~~~

The root password.

Default: not set (``False``).

.. _pillar-parent_hosts:

parent_hosts
~~~~~~~~~~~~

A list of the minion ID of the "parent" hosts for this minion. This will be
used as a value of `parents
<http://shinken.readthedocs.org/en/latest/05_thebasics/networkreachability.html>`_
directive in :doc:`/shinken/arbiter/doc/index`.
When all its parents are down or unreachable, the host will be unreachable
instead of down.

Default: no parent hosts (``[]``).
