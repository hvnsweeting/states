Usage
=====

Follow the generic logic of pillar, apply formula and run checks, then perform
the followings.

Firstly, access one of the hostname that was specified at
:ref:`pillar-jenkins-hostnames` to access :doc:`/jenkins/doc/index` web UI.

Things you **should** do
------------------------

- Enable security in **Configure Global Security** to ``/configureSecurity/`` URL
  and have one account per user.
  After that, switch to **Matrix-based security** to prevent anonymous user to
  have read-only access to Jenkins.
- Install https://wiki.jenkins-ci.org/display/JENKINS/Timestamper and turn it
  on to all jobs.
- Set ``[a-zA-Z0-9\-]*`` as regular expression for job name. As job name are
  used to create VM hostname, this need to be a valid hostname.
- Do following steps in ``Manage Jenkins``.
- Set ``System Admin e-mail address``.
- Raise number of executor (``# of executors``) to large value such as ``20``.
- Set ``Jenkins URL`` to first value of ``jenkins:hostnames``.
- Configure SMTP to send email for build status change.

Manage Users
------------

Create
~~~~~~

Go to ``/securityRealm/addUser`` and fill the form and use a randomly generated secure
password. Click on **Sign up**.

Let know that person the username and password of the account with one of the hostname
in :ref:`pillar-jenkins-hostnames`.

.. warning::

  It's suggested to ask users to change their own password after first time they log in.

Then, grant the permission to that user at ``/configureSecurity/``, in **Authorization**
section, **Matrix-based security** sub-section, fill the newly created username in
**User/group to add**, click add. Select the various permission that user requires.

Delete
~~~~~~

Simply click on the red circle and a line on the user list ``/securityRealm/`` or go to
``/securityRealm/user/{{ USERNAME }}/delete``. With targeted username.

Edit
~~~~

Click on the tools icons on the user list ``/securityRealm/`` or go to
``/securityRealm/user/{{ USERNAME }}/configure``. With targeted username.

Useful plugins
--------------

.. note::

  all paths such as ``/log/all``, ``/configure`` are parts of URL after
  address of running :doc:`/jenkins/doc/index` server.

Multiple SCMs
~~~~~~~~~~~~~

https://wiki.jenkins-ci.org/display/JENKINS/Multiple+SCMs+Plugin

Allow to checkout multiple repositories for a single project, such as more than
one :doc:`/git/server/doc/index`.

.. warning::

  This plugin don't work as expected on Jenkins slaves. You need to specify an
  ``Additional Behaviours``, choose ``Checkout to a sub directory`` and set
  ``Local subdirectory for repo``.

Build User Vars Plugin
~~~~~~~~~~~~~~~~~~~~~~

https://wiki.jenkins-ci.org/display/JENKINS/Build+User+Vars+Plugin

This plugin is used to set user build variables.

Builds that Disapears
~~~~~~~~~~~~~~~~~~~~~

https://issues.jenkins-ci.org/browse/JENKINS-15156

The workaround is go ``/manage`` (Manage Jenkins) and click
**Reload Configuration from Disk**

Even if the bug 15156 had been marked as fixed, the problem still exists.

Log Jenkins to syslog
~~~~~~~~~~~~~~~~~~~~~

https://wiki.jenkins-ci.org/display/JENKINS/Syslog+Logger+Plugin

Used to send :doc:`index` log to syslog. It's configurable through options in
``/configure``.

ClamAV Plugin
~~~~~~~~~~~~~

https://wiki.jenkins-ci.org/display/JENKINS/ClamAV+Plugin

This plugin allows you to check the artifacts with :doc:`/clamav/doc/index`,
which is an open source (GPL) antivirus engine designed for detecting Trojans,
viruses, malware and other malicious threats.

A :doc:`/clamav/doc/index` server instance installed in network mode is
required.

Go Plugin
~~~~~~~~~

https://wiki.jenkins-ci.org/display/JENKINS/Go+Plugin

Plugin allows build Golang projects with Jenkins.

.. note::

  from Jenkins 1.608+, when install Go plugin 1.1 may cause ``/configure``
  failed to load, see a workaround here:
  https://issues.jenkins-ci.org/browse/JENKINS-27499

Role Strategy Plugin
~~~~~~~~~~~~~~~~~~~~

https://wiki.jenkins-ci.org/display/JENKINS/Role+Strategy+Plugin

Add role-based strategy to ease and fasten users management.

Warnings Plugin
~~~~~~~~~~~~~~~

https://wiki.jenkins-ci.org/display/JENKINS/Warnings+Plugin

This plugin generates the trend report for compiler warnings in the console log
or in log files.
