Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/apt/doc/index` :doc:`/apt/doc/pillar`
- :doc:`/pip/doc/index` :doc:`/pip/doc/pillar`
- if ``sentry:ssl`` is defined :doc:`/ssl/doc/index` :doc:`/ssl/doc/pillar`

Mandatory
---------

Example::

  shinken:
    webui:
      auth_secret: ooyoogheiNiex3bohmaiYaishooph5xa
    graphite_url: http://graphite.example.com
    users:
      username:
        email: noreply@example.com
        password: secr3t
    architecture:
      broker:
        - integration-0
      arbiter:
        - integration-0
      scheduler:
        - integration-0
      reactionner:
        - integration-0
      poller:
        integration-0: all
    hostname:
      - shinken.example.com

.. _pillar-shinken-webui-auth_secret:

shinken:webui:auth_secret
~~~~~~~~~~~~~~~~~~~~~~~~~

The private key to build cookie.

.. _pillar-shinken-graphite_url:

shinken:graphite_url
~~~~~~~~~~~~~~~~~~~~

:doc:`/graphite/doc/index` address.
Should be one value in :ref:`pillar-graphite-hostnames`.

.. _pillar-shinken-users:

shinken:users
~~~~~~~~~~~~~

List contact users.
Please replace {{ username }} by real username.

.. _pillar-shinken-users-username-email:

shinken:users:{{ username }}:email
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:doc:`index` user's email

.. _pillar-shinken-users-username-password:

shinken:users:{{ username }}:password
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:doc:`index` user's password

.. _pillar-shinken-architecture-broker:

shinken:architecture:broker
~~~~~~~~~~~~~~~~~~~~~~~~~~~

List of :ref:`shinken-broker` IDs.

.. _pillar-shinken-architecture-arbiter:

shinken:architecture:arbiter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

List of :ref:`shinken-arbiter` IDs.

.. _pillar-shinken-architecture-scheduler:

shinken:architecture:scheduler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

List of :ref:`shinken-scheduler` IDs.

.. _pillar-shinken-architecture-reactionner:

shinken:architecture:reactionner
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

List of :ref:`shinken-reactionner` IDs.

.. _pillar-shinken-architecture-poller:

shinken:architecture:poller
~~~~~~~~~~~~~~~~~~~~~~~~~~~

List of :ref:`shinken-poller` IDs.

.. _pillar-shinken-architecture-poller-id:

shinken:architecture:poller:{{ id }}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Data formed as a dictionary: ``id``:``poller_tags``

shinken:hostnames
~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/hostnames.inc

Optional
--------

Example::

  ip_addrs:
    public: 1.2.3.4
    private: 1.4.5.6
  monitor: False
  shinken:
    users:
      ro:
        read_only: True
        email: ro@example.com
        password: pass
        notification: False
        warning_contact: True
        managed_hosts:
          - foo
          - bar
    architecture:
      receiver:
        - integration-0
    poller_max_fd: 16384
    ssl: False
    ssl_redirect: False
    log_level: DEBUG
    nrpe:
      timeout: 30
    mattermost:
      webhook_url: https://mattermost.example.com/hooks/privatetoken
    slack:
      channel: general
      token: xoxp-12182635943-12182635959-12180504788-f1b6c190a6
      managed_hosts:
        - host1
        - host2

.. _pillar-ip_addrs:

ip_addrs
~~~~~~~~

In the ``_modules/monitoring.py``, there is a function name `data()` that is
used to gather specific data of a minion for monitoring.

Define public and private IP of a minion.

Default: Unused (``{}``)

.. _pillar-ip_addrs6:

ip_addrs6
~~~~~~~~~

Same as :ref:`pillar-ip_addrs` but for :ref:`glossary-IPv6`.

Default: Unused (``{}``)

shinken:ip_source
~~~~~~~~~~~~~~~~~

By default :doc:`index` will use public IP for internal connection. If set this
value to ``'private'``, private IP will be using instead. Public and private IPs
can be explicit set using :ref:`pillar-ip_addrs` or automatically collected in
case of Amazon EC2 instances.

Possible values:

* ``'private'``
* ``'public'``

Default: use public IP (``'public'``).

.. _pillar-monitor:

monitor
~~~~~~~

Whether this minion is monitored by Shinken or not.

Default: is monitored (``True``)

.. _pillar-monitoring_data:

monitoring_data
~~~~~~~~~~~~~~~

Extra value can be passed to the Shinken for monitoring.

Default: No extra value (empty dictionary ``{}``).

.. _pillar-shinken-users-username-read_only:

shinken:users:{{ username }}:read_only
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Whether this user has only read permission in the Web UI or not.

Default: is an admin and can submit the commands (``False``).

.. _pillar-shinken-architecture-receiver:

shinken:architecture:receiver
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

List of :ref:`shinken-receiver` IDs.

Default: Unused (empty list ``[]``).

.. _pillar-shinken-poller_max_fd:

shinken:poller_max_fd
~~~~~~~~~~~~~~~~~~~~~

Maximum number of `file descriptors
<http://en.wikipedia.org/wiki/File_descriptor>`_ poller can allocate.

Default: ``16384``.

.. _pillar-shinken-ssl:

shinken:ssl
~~~~~~~~~~~

.. include:: /nginx/doc/ssl.inc

.. _pillar-shinken-ssl_redirect:

shinken:ssl_redirect
~~~~~~~~~~~~~~~~~~~~

.. include:: /nginx/doc/ssl_redirect.inc

.. _pillar-shinken-log_level:

shinken:log_level
~~~~~~~~~~~~~~~~~

Define level of logging.

Default: just log informational messages (``INFO``).

.. _pillar-shinken-slack:

shinken:slack
~~~~~~~~~~~~~

Whether to send a notification to `Slack <https://slack.com/>`_ or not.

Default: turn off (``False``).

.. _pillar-shinken-mattermost:

shinken:mattermost
~~~~~~~~~~~~~~~~~~

Whether to send a notification to :doc:`/mattermost/doc/index` web hook
or not.

Default: do not use (``False``).

Conditional
-----------

.. _pillar-shinken-mattermost-webhook_url:

shinken:mattermost:webhook_url
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Webhook URL to send notification to.

.. _pillar-shinken-slack-channel:

shinken:slack:channel
~~~~~~~~~~~~~~~~~~~~~

Which channel a notification will be sent to.

.. _pillar-shinken-slack-token:

shinken:slack:token
~~~~~~~~~~~~~~~~~~~

Which token will be used to authenticate.

It can be generated by:

- Login to the `Slack <https://slack.com/>`_ API
- Choose ``Web API`` on the left side
- Scroll down and click on the ``Issue token`` button

Only used if :ref:`pillar-shinken-slack` is defined.

.. _pillar-shinken-slack-managed_hosts:

shinken:slack:managed_hosts
~~~~~~~~~~~~~~~~~~~~~~~~~~~

List of hosts that ``slack`` is the contact of.

Default: send notification of all hosts to the `Slack <https://slack.com/>`_
(``[]``).

.. _pillar-network-interface:

network_interface
~~~~~~~~~~~~~~~~~

The network interface of a minion which is used for monitoring.

Default: The first network interface (``eth0``)

Only used if :ref:`pillar-ip_addrs` is not defined.

.. _pillar-shinken-users-username-notification:

shinken:users:{{ username }}:notification
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Whether to send a notification to user {{ username }} or not.

Default: send a notification to user {{ username }} (``True``).

Only used if :ref:`pillar-shinken-users-username-read_only` is True.

.. _pillar-shinken-users-username-warning_contact:

shinken:users:{{ username }}:warning_contact
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Whether to send a warning notification to user {{ username }} or not.

Default: not send a warning notification to user {{ username }} (``False``).

Only used if :ref:`pillar-shinken-users-username-warning_contact` is True

.. _pillar-shinken-users-username-managed_hosts:

shinken:users:{{ username }}:managed_hosts
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

List of managed hosts that the user {{ username }} is the contacts of.

Default: user {{ username }} is not the contact of any host (``[]``).

Only used if :ref:`pillar-shinken-users-username-read_only` is True.
