Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/pip/doc/index` :doc:`/pip/doc/pillar`
- :doc:`/rsyslog/doc/index` :doc:`/rsyslog/doc/pillar`
- :doc:`/ssh/client/doc/index` :doc:`/ssh/client/doc/pillar`

Optional
--------

Example::

    salt_master:
      gitfs_remotes:
        - git@git.example.com:common.git
        - git@git.example.com:states.git
        - git@git.example.com:anotherstates.git: subdir
      extra_envs:
        - windows: git@git.example.com:namespace/windows-formulas.git
        - git@git.example.com:namespace/osx.git
      workers: 1
      ext_pillar:
        git:
          - develop gitlab@git.example.com:dev/pillars.git
          - master:prod gitlab@git.example.com:dev/pillars.git

.. _pillar-salt_master-gitfs_remotes:

salt_master:gitfs_remotes
~~~~~~~~~~~~~~~~~~~~~~~~~

.. copied from https://github.com/saltstack/salt/blob/2014.1/conf/master#L385

`Git fileserver <http://docs.saltstack.com/en/latest/topics/tutorials/gitfs.html>`_
backend configuration.
When using the fileserver backend at least one :doc:`/git/doc/index` remote
needs to be defined.

The user ``root`` running the :doc:`/salt/master/doc/index` need read
access to the :doc:`/git/doc/index` repositories.
The pillar key :ref:`pillar-ssh-keys` is probably
required  and it's key authorized to read the
repository. And the server :ref:`pillar-ssh-hosts` defined too.

Look in :doc:`/ssh/client/doc/index` for more details, more importantly the
following pillar keys are probably required:

If the :doc:`index` act also as the :doc:`/git/server/doc/index`, look for
:doc:`/git/server/doc/pillar` exact pillars keys details.

.. note::

  To use a subdir from the checkout of an repo as a file root, specify the
  dirname after the git link, separated by a ``:``.

Default: ``[]``.

.. warning::

  Make sure there is no branch names under a sub-directory namespace
  (with a ``/`` into it. This cause Salt 2014.1.x to fail.

.. _pillar-salt_master-extra_envs:

salt_master:extra_envs
~~~~~~~~~~~~~~~~~~~~~~

A list of extra environments. The element can be a dictionary with key is the
environment name and value is the git URL, or it can just be a git URL, then
the environment name will be pick up from the basename.

Default: no extra environment (``[]``).

.. _pillar-salt_master-git_pull_frequency:

salt_master:git_pull_frequency
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

How often does repositories in :ref:`pillar-salt_master-gitfs_remotes` be
fetched (in minutes, only allows value from ``0`` to ``59``).

Default: ``5`` minutes.

.. _pillar-salt_master-ext_pillar-git:

salt_master:ext_pillar:git
~~~~~~~~~~~~~~~~~~~~~~~~~~

List of repositories which is specified in the format `<branch> <repo_url>` or
`<branch>:<env> <repo_url>`.

Default: not used (``[]``).

.. _pillar-salt_master-loop_interval:

salt_master:loop_interval
~~~~~~~~~~~~~~~~~~~~~~~~~

.. https://github.com/saltstack/salt/blob/2014.1/conf/master#L80

The loop_interval option controls the seconds for the master's maintinance
process check cycle. This process updates file server backends, cleans the
job cache and executes the scheduler.

Default: ``60``.

.. _pillar-salt_master-keep_jobs_hours:

salt_master:keep_jobs_hours
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. https://github.com/saltstack/salt/blob/2014.1/conf/master#L73

Set the number of hours to keep old job information in the job cache

Default: ``24``.

.. _pillar-salt_master-gather_job_timeout:

salt_master:gather_job_timeout
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The number of seconds to wait when the client is requesting information about
running jobs.

Default: ``5``.

.. _pillar-salt_master-reactor:

salt_master:reactor
~~~~~~~~~~~~~~~~~~~

Automatically process most of the common events, such as run ``state.highstate``
on newly created minion with :doc:`/salt/cloud/doc/index`.

Default: turn it off (``False``).

.. _pillar-salt_master-workers:

salt_master:workers
~~~~~~~~~~~~~~~~~~~

Numbers of workers.

Default: uses number of CPU cores (``None``).

Conditional
-----------

.. _pillar-salt_master-highstate_days:

salt_master:highstate_days
~~~~~~~~~~~~~~~~~~~~~~~~~~

A list of days :doc:`index` will run highstate on all VMs which has
:ref:`pillar-salt-highstate` set to ``True``.

The day is in the number format (same as the :doc:`/cron/doc/index`): 0 to 6
are Sunday to Saturday.

.. _pillar-salt_master-mine_ignores:

salt_master:mine_ignores
~~~~~~~~~~~~~~~~~~~~~~~~

List of salt minions that will be ignore in :ref:`monitor-salt_master_mine`
monitoring check.

Default: ignore no minion (``[]``).
