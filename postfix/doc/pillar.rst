Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/apt/doc/index` :doc:`/apt/doc/pillar`
- :doc:`/mail/doc/index` :doc:`/mail/doc/pillar`
- :doc:`/openldap/doc/index` :doc:`/openldap/doc/pillar`
- :doc:`/ssl/doc/index` :doc:`/ssl/doc/pillar` if :ref:`pillar-postfix-ssl` is
  set.

.. note::

    To create a full-featured email stack, with :doc:`/openldap/doc/index`,
    :doc:`/dovecot/doc/index`, ...
    value of :ref:`pillar-mail-mailname` must be put into pillar
    :ref:`pillar-postfix-domains`,
    :doc:`index` variable "$mydomain" can be used as well.

Mandatory
---------

Example::

  mail:
    mailname: domain.ltd

.. _pillar-postfix-myhostname:

postfix:myhostname
~~~~~~~~~~~~~~~~~~

Hostname of this SMTP server, which is used for A record for mail server.
Appended by a dot ``.`` then :ref:`pillar-mail-mailname`. This often should set
to "mail".
Be mandatory pillar here to make sure administrator not making mistake (i.e
wrongly named host, that makes :doc:`index` auto use default
WRONG-HOSTNAME.domain.ltd as address for outgoing emails), which can badly lead
to email will end in spam box.

Optional
--------

Example::

  mail:
    maxproc: 2

  postfix:
    domains:
      - domain.ltd
    spam_filter: True
    allow_remote_client: True
    virtual_aliases: |
        user1.abc@example.com user1@example.com
        user2.xyz@example.com user2@example.com
    alias_domains:
      - saltlint.org
      - saltci.org
    message_size_limit: 15360000
    mynetworks:
      - 127.0.0.0/8
      - 192.168.122.0/24
    queue_length: 50

  ldap:
    data:
      mailname:
        user1:
          cn: CN user1
          sn: SN user1
          passwd: password of user1 (plaintext or created by ldappasswd)
          desc: description for user1
          email: other email of user1
        user2:
          cn: CN user2
          sn: SN user2
          passwd: password of user2
          desc:
          email:

.. _pillar-postfix-mydestination:

postfix:mydestination
~~~~~~~~~~~~~~~~~~~~~

List of `canonical domains
<http://www.postfix.org/VIRTUAL_README.html#canonical>`_
that this mail server will be final `destination
<http://www.postfix.org/postconf.5.html#mydestination>`_.
Consult http://www.postfix.org/postconf.5.html#mydestination for more detail.

To support multiple domains on one server, using virtual mailboxes will
help without any problem compared to the canonical domain. List of domains
(called `Hosted domains
<http://www.postfix.org/VIRTUAL_README.html#canonical>`_)
can be specified in :ref:`pillar-postfix-domains`.

Default: allow sending local mail to UNIX mailboxes
(``['localhost', 'localhost.$mydomain']``). It's possible to redirect those
mails to other addresses (see :ref:`pillar-postfix-aliases`)

.. _pillar-postfix-domains:

postfix:domains
~~~~~~~~~~~~~~~

List of domains that :doc:`index` will receive emails for.
If one needs to setup mail server for domain ``mydomain.com``, this pillar
should be set as following::

  postfix:
    domains:
      - mydomain.com

This will translate to value of :doc:`index` configure directive
``virtual_mailbox_domains``.
Mails are delivered via the ``virtual_transport``.
Consult http://www.postfix.org/postconf.5.html#virtual_mailbox_domains
for more information.

.. warning::

  ensuring these values must not be set in :ref:`pillar-postfix-mydestination`
  pillar.  $mydomain and $myhostname must not set in
  :ref:`pillar-postfix-mydestination`, too.

.. note::

  it is possible to use :doc:`index` variable such as ``$mydomain``,
  ``$myhostname``, etc...

Default: not used (``[]``).

.. _pillar-postfix-spam_filter:

postfix:spam_filter
~~~~~~~~~~~~~~~~~~~

Enable :doc:`/amavis/doc/index` spam filter.

Default: disabled (``False``).

.. _pillar-postfix-allow_remote_client:

postfix:allow_remote_client
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Allowing remote :ref:`glossary-smtp` client (who does not in the same network
with :doc:`index`) to authenticate and if it successes,
allow it to send email. This done by using :doc:`/dovecot/doc/index`
`SASL <http://wiki2.dovecot.org/Sasl>`_.

Default: allow only clients in the same network to send mail (``False``).
Set it to ``True`` will add several SASL-relate
configuration directives into :doc:`index` main configuration file to allow
clients to login and send email remotely.

.. _pillar-postfix-virtual_aliases:

postfix:virtual_aliases
~~~~~~~~~~~~~~~~~~~~~~~

Support `alias(mail forwarding)
<http://www.postfix.org/postconf.5.html#virtual_alias_maps>`_.
for virtual mailboxes.  Multiple lines string, uses below syntax::

  <source_addr> <dest_addr>
  <source_addr2> <dest_addr2>

Be carefully, or it may cause recursive forwarding.

Default: no aliasing (``False``).

.. _pillar-postfix-ssl:

postfix:ssl
~~~~~~~~~~~

Name of :doc:`/ssl/doc/index` key to support :ref:`glossary-smtp`
over :doc:`/ssl/doc/index`
(`SMTPS <http://en.wikipedia.org/wiki/SMTPS>`_).

Default: not support SMTPS (``False``).

.. _pillar-postfix-message_size_limit:

postfix:message_size_limit
~~~~~~~~~~~~~~~~~~~~~~~~~~

The maximal size in bytes of a message.

Default: default value of :doc:`index` (``10240000``).

.. _pillar-postfix-mynetworks:

postfix:mynetworks
~~~~~~~~~~~~~~~~~~

List of trusted networks that :doc:`index` will relay mail from.
Consults http://www.postfix.org/postconf.5.html#mynetworks for more detail.

Default: Trust only `loopback network
<http://en.wikipedia.org/wiki/Localhost#Name_resolution>`_
(``['127.0.0.0/8']``).

.. _pillar-postfix-relayhost:

postfix:relayhost
~~~~~~~~~~~~~~~~~

The next-hop destination of non-local mail; overrides non-local domains in
recipient addresses. Consult http://www.postfix.org/postconf.5.html#relayhost
for more details.

Default: send all emails directly - set value to an empty string(``''``).

.. _pillar-postfix-relay_domains:

postfix:relay_domains
~~~~~~~~~~~~~~~~~~~~~

Domains that this mail server will relay mail to.

Default: relays mails to all domain defined in
:ref:`pillar-postfix-mydestination` (``['$mydestination']``).

.. _pillar-postfix-inet_interfaces:

postfix:inet_interfaces
~~~~~~~~~~~~~~~~~~~~~~~

Network interfaces that this mail server listen to.

Default: listen to all interfaces available (``all``).

.. _pillar-postfix-queue_length:

postfix:queue_length
~~~~~~~~~~~~~~~~~~~~

Warning if the number of items in the mail queue reach the defined threshold.

Default: ``20`` items in queue to raise warning.

.. _pillar-postfix-aliases:

postfix:aliases
~~~~~~~~~~~~~~~

Aliases table content for redirecting mail for
`local recipients <http://www.postfix.org/LOCAL_RECIPIENT_README.html>`_.

Multiple lines string, use below syntax::

  <local_addr>:    <dest_addr>
  <local_addr2>:    <dest_addr2>

For example, to redirect all mail to ``root`` account to another address, set
this pillar as bellow::

  postfix:
    aliases: |
      root:    admin@yourdomain.com

Default: forward UNIX `root`'s mails to address defined
in :ref:`pillar-mail-postmaster` (``False``).

Conditional
-----------

.. _pillar-postfix-alias_domains:

postfix:alias_domains
~~~~~~~~~~~~~~~~~~~~~

:doc:`index` will receive email for those domains and forward to addresses
specified in :ref:`pillar-postfix-virtual_aliases`.

.. warning::

   ensuring these values must not be set in :ref:`pillar-postfix-mydestination`
   pillar key.

Default: ``['$virtual_alias_maps']`` - uses same value with $virtual_alias_maps
This is :doc:`index` `default value
<http://www.postfix.org/postconf.5.html#virtual_alias_domains>`_.

Example, if one wants to receive email for address ``salt@example.org`` then
forward it to email ``saltstack@example.com``, following pillar keys should be
set::

  postfix:
    alias_domains:
      - example.org
    virtual_aliases:
      salt@example.org saltstack@example.com

Only use if the :ref:`pillar-postfix-aliases` is ``True``.
