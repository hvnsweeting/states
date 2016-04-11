Usage
=====

.. TODO: FIX

.. note::

  consults :doc:`/jenkins/doc/usage` for configure :doc:`/jenkins/doc/index`
  guide.

Notice
------

Since each build job clones code from :doc:`/gitlab/doc/index` server, user may
need to specify the Credential for each git link if needed. If
:doc:`/gitlab/doc/index` server uses :doc:`/fail2ban/doc/index`,
user must specify Credential before adding git link,
or adds address of CI server to :ref:`pillar-fail2ban-whitelist` of
:doc:`/gitlab/doc/index` server.

Update pillar
-------------

Test VMs will copy result to CI server after done testing, it is done through
scp command instead of salt-cp to avoid security problems. To make scp work,
it must set pillar :ref:`pillar-salt_ci-host_key` to host key of CI server. See
:doc:`/ssh/doc/index` for instruction.
NOTICE: the address part in this key should be the same as value in
:ref:`pillar-salt_cloud-master` (do not use domain in one and IP in another)

Plugins
-------

Install following plugins:

- Execute shell task in ``Post-build actions``: postbuildscript (https://wiki.jenkins-ci.org/display/JENKINS/PostBuildScript+Plugin)
- Checkout source code with git: git (https://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin)
- Use multiple SCMs: multiple-scms (https://wiki.jenkins-ci.org/display/JENKINS/Multiple+SCMs+Plugin)

Configuration
-------------

Notices that some config options only available after installing all needed
plugins, so do install above plugins before doing followings steps.

- Configure :doc:`/ssh/doc/index` private key
  for user ``jenkins`` through :doc:`/jenkins/doc/index` Web UI. (Dashboard => Credential
  => Add credential => `Kind: SSH username with private key`

Jobs
----

A testing job should be created with the following:

**Execute concurrent builds if necessary** turned on.

Select ``Multi SCM`` as **Source Code Management**. You need 2 git
repositories:

- Common states
- Pillars repo

In each instance of Multi SCM, at ``Additional Behaviours``, choose
``Check out to a sub-directory`` and set to ``common``, ``pillar``
respectively.

Specify the tested branch, never put ``**`` or a single click on **build**
can trigger 200 builds.

In Build section, add a build step by choosing
``Add build step`` > ``Execute shell``::

    $WORKSPACE/common/test/jenkins/build.sh vim

which will run build script from path
``$WORKSPACE/common/test/jenkins/build.sh`` with one argument ``vim``,
this make build job run all test against ``vim`` formula.
To add more tests, just pass them as arguments to this script (separate
by space). To run all test, provide no argument.

You may also want to adding following post-build actions:

- ``Archive the artifacts``
- ``Publish JUnit test result report``
- ``Execute a set of scripts`` and run
  ``$WORKSPACE/common/test/jenkins/post.sh`` script to delete created VM
- ``E-mail Notification`` to send email whenever a build fails.
