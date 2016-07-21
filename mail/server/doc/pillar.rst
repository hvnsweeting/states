Pillar
======

.. include:: /doc/include/pillar.inc

Mandatory
---------

Example::

  mail:
    postmaster: test@robotinfra.com

.. _pillar-mail-postmaster:

mail:postmaster
~~~~~~~~~~~~~~~

Address of who act as postmaster (mail admin), this address will receive
all problems that happen in mail system (E.g: spam report, virus report, ...)

Optional
--------

Example::

  mail:
    check_mail_stack:
      smtp_wait: 25

.. _pillar-mail-check_mail_stack:

mail:check_mail_stack
~~~~~~~~~~~~~~~~~~~~~

Pillar keys for :doc:`/nrpe/doc/index` check functionality of a mail stack.
If this pillar key is not defined, the check will not be enabled.

Default: do not check mail stack functionality (``{}``).

.. _pillar-mail-maxproc:

mail:maxproc
~~~~~~~~~~~~

Maximum number of processes of:

- ``amavisd`` child processes (not including the main process).
- ``amavisfeed``, :doc:`/amavis/doc/index` service of :doc:`/postfix/doc/index`

Default: ``2`` processes each.  This value reflects the default of 2
amavisd-daemon children processes and is a good setting to start from.
The value may be raised later, when the system works stable and still
can take a higher load. Same value used to configurate both software
as one of :doc:`/postfix/doc/index` should never exceed one of
:doc:/doc/amavis/index`.
Consult http://www.ijs.si/software/amavisd/README.postfix for more detail.

Conditional
-----------

.. _pillar-mail-check_mail_stack-username:

mail:check_mail_stack:username
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Username of mail account dedicated for testing, do not use in common with other
account. Do not need to specify the domain path of this username. This must be
one pillar key defined in :doc:`/openldap/doc/index`.

.. _pillar-mail-check_mail_stack-smtp_server:

mail:check_mail_stack:smtp_server
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SMTP server used for sending email, as the NRPE check is installed on
dovecot server, SMTP server does not always need to be allocated in the same
server.

.. _pillar-mail-check_mail_stack-smtp_wait:

mail:check_mail_stack:smtp_wait
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Time (in seconds) to wait after send an email. As the mail processing may take
time to scan and transport the email.

Default: ``25`` seconds.
