Introduction to this repository
===============================

Welcome to **Common** repository.

This repository targets Linux only. It actually only supports Ubuntu 12.04
Precise LTS and Ubuntu 14.04 Trusty LTS but support for other releases of
`Ubuntu <http://www.ubuntu.com>`_
or `Debian <http://www.debian.org>`_ based distributions can be easily added.

It contains the low-level salt states for various operating-system services,
such as:

- :doc:`logging daemon </rsyslog/doc/index>`
- :doc:`package manager </apt/doc/index>`
- :doc:`/ssh/server/doc/index`
- cron
- logging rotation
- :doc:`/ntp/doc/index` client and server
- sudo
- :doc:`Simple SMTP client </ssmtp/doc/index>`
- screen

and numerous states for tools used by itself to deploy applications, such as:

- :doc:`/git/doc/index`
- Mercurial
- :doc:`/ssh/client/doc/index` client
- Python PIP
- Python virtualenv
- :doc:`/ssl/doc/index` keys
- Python
- Ruby

It also contains less generic services that might be used by other applications,
such as:

- :doc:`/rabbitmq/doc/index` ActiveMQ bus
- :doc:`/nginx/doc/index` web server
- :doc:`/memcache/doc/index` daemon
- NodeJS
- :doc:`/uwsgi/doc/index` application server
- :doc:`/django/doc/index`

Databases SQL or NoSQL, such as:

- :doc:`/postgresql/doc/index`
- :doc:`/elasticsearch/doc/index`
- :doc:`/mongodb/doc/index`

States that protect the server, such as:

- :doc:`/fail2ban/doc/index` to block bruteforce SSH attacks
- :doc:`/firewall/doc/index`
- :doc:`/clamav/doc/index` anti-virus
- :doc:`/openvpn/doc/index` to secure communication

States to deploy complex tools that is used to support the Infrastructure in
various ways, such as:

- :doc:`/graylog2/doc/index` centralized logging
- Statistic and graphics using :doc:`/graphite/doc/index`
- :doc:`/shinken/doc/index` distributed monitoring
- Configuration management using :doc:`/salt/doc/index`
- :doc:`/sentry/doc/index` for error notification and reporting
- :doc:`/backup/doc/index`

Standalone daemon state, such as:

- :doc:`/proftpd/doc/index`
- :doc:`/git/server/doc/index`

States for integration of various components at operating system level:

- :doc:`/diamond/doc/index`, a daemon that gathers statistics on thousands of
  metrics and sends it to :doc:`/graphite/doc/index`.
- :doc:`/nrpe/doc/index` (Nagios Remote Plugin Executor), called by
  :doc:`/shinken/doc/index` server to perform checks.
- Raven client to report error to Sentry.
- :doc:`/statsd/doc/index`, a daemon that receives stats from some applications
  and periodically sends them to :doc:`/graphite/doc/index`.

Other states, such as:

- Salt web UI
- :doc:`Salt web UI </salt/api/doc/index>`
- An :ref:`glossary-APT` repository server to host your own :ref:`glossary-Debian` packages

States for testing and its requirements.
More details on this topic in file testing document.

Philosophy
----------

This repository deploys only Open-Source software (OSS), so far. By building a
complete infrastructure on top of OSS guarantee that these states don't
depend on a specific individual or company. The deployed software can be
troubleshoot and fixed internally. If an OSS community still exists around any
software that causes an issue, the community can fix the bug and help to improve
the running infrastructure for free.

If the authors and/or maintainers of that repository aren't available anymore
to support it, anybody can take over it.

All the states had been designed to configure themselves from Salt Pillar data.
Some configuration are hardcoded because they're linked to a specific release of
the component the state deploy. As it's still unknown what upcoming
releases will require, the state lock itself on specific version.

The limitations of those states are the limitations of the deployed software.
Example: if a component is known to not scale on more than 100 servers.
The state will only be able to achieve a scalable deployment to 100 servers.
If an OSS application contains a bug that affect the infrastructure, the state
can't be blamed for it. It's just a recipe that deploys infrastructure and
manages configurations.

The states come with highly polished integration between themselves and the
infrastructure support tools. The integration is optional but highly
recommended.

The states and pillars are documentations! These states try to do everything
requires to have a fully working application. Human intervention is avoided at
all costs.
This allow to only backup the data that is produced by the application, for
example: In :doc:`/postgresql/doc/index`, it's the dump of all databases. As the
configuration files are managed by the states and pillars, they don't need to be
backup. Nor the binaries, as they're available through the package manager.
So, well documented states and pillars can document what the infrastructure is
and how global pieces are plugged together. Thus eliminate most of the documents
requirements and make it very easy to plan a disaster recovery plan.
By eliminating all human intervention on the servers themselves, except for
the data, you remove the "surprise" element of an expected configuration in a
server.

This repository contains only low-levels states. Low-level means that they only
perform changes on the server itself on specific applications or the operating
system itself. This repository alone with pillars, can't even execute salt
``state.highstate`` function. But, each state can be executed through
``state.sls``.
This repository don't contains business logic, orchestration or integration. It
need to be into another repository. This allows this **common** repository to
never contains client's specific changes and stays generic and usable by
everyone. No need to merge changes from one repo to another. These states
don't contain undisclosable information.
If a low-level state requires a client's change that can't be shared to everyone
its kept in the client's specific repository (or repositories).
GitFS feature of Salt allows to have multiple repositories plugged together
without causing any potential conflicts. All repositories content are then,
considered as a single flat merged file-system.

Infrastructure Support
----------------------

Most of the states of that repository are there to fill the requirements to
deploy web application, internal developed software or any commercial closed
source application.

But some of them exists only to support other components:

- Monitoring:

  - Check that components run as expected.
  - Perform additional validation that are mostly useful when a component
    doesn't work as expected and someone tries to troubleshoot the issue.
  - Notify by email about any problem and its recovery.
  - Web interface to see actual problems, check history of a service or a
    host. Or a dashboard that shows status of various system.
  - Business health status, for example: a cluster is working as expected if at
    least 2 out of 3 nodes are working. If 2 nodes don't work and only 1 does,
    the status is at Warning and only support team get notification.
    If 3 nodes are down, everyone will get a notification that the status is
    Error.

- Centralize into a single place all logs from all hosts:

  - To provide a single place to look for information.
  - Create alert based on some rules, such as Linux OOM (Out of Memory).
  - Give access to developers or tester to logs of some hosts.
  - Limit human requirements to log into a server to read logs, which limits
    the risks for someone to perform live changes on the server that aren't
    tracked by configuration management system.

- Metrics Statistics and graphics:

  - A central dashboard that show graphics on thousands of metrics generated by
    each component of the infrastructure. The most basic one are CPU usage of
    a host, or a process memory usage.
  - This complete the monitoring. Monitoring server even uses stats and
    graphs component to store and display its own performance data.
  - Any internally developed application can be changed to send internal metrics
    too and embedded graphics into it.

- Error reporting:

  - Many states come with integration to an error reporting server, if the
    application allows it. When an internal error happens, the error is reported
    immediately instead of silently lost in the logs.
  - A Linux based infrastructure with a lot of OSS components often come with
    multiple ways to get notification if something goes wrong, such as logs in
    its own file, logs through syslog, local email, email through a remote SMTP
    server, etc. The states in this repository are built to limit those
    communications channels and send them to the error report server to make
    sure that multiple people can all receive the same error message.
    If an error happens 1000 times in a row, only a single notification is sent
    The error can be acknowledge.

- Configuration Management:

  - Everything is done through states,
    **even the first salt-master installation!**. No surprise, no undocumented
    installation steps, no results that can't be reproduce.
  - States life-cycles: this repository support multiple version of the states
    to be usable at the same time. A single host can execute the stable version
    of the states, while a testing host can execute another version that just
    went out of development.

Integration
-----------

Most of the states come with a sub-state that integrate themselves with other
components, such as monitoring (through :doc:`/nrpe/doc/index`), statistics and
graphs (through :doc:`/graphite/doc/index`) and logging (to filter noise out of
logs).

Those sub-states with integration aren't required to install the parent state.
Such as :doc:`/postgresql/doc/index` state can be deployed without
:doc:`/nrpe/doc/index` monitoring checks,
:doc:`/diamond/doc/index` plugin configuration or client-side backup script.

A lot of other states also directly integrate themselves when they have
native support for technologies, such as built-in :doc:`/graylog2/doc/index`
support in :doc:`/uwsgi/doc/index`.
through its GELF plugin. Or through third party library, such as GrayPY for
Python based application. In those cases, the integration is turned on only
when Salt pillar data contains an expected value.

High-Availability and High-Performance
--------------------------------------

Many states support clustering and the support infrastructure components had
been chosen because they support some form or an other of high-availability
(HA) or high-performance (HP).

Actually, the HA and/or HP features aren't all turned on in current version of
the states in that repository.

Only the following support both HA and HP:

- :doc:`/elasticsearch/doc/index`
- :doc:`/rabbitmq/doc/index` ActiveMQ bus
- :doc:`/shinken/doc/index` monitoring

The following states will soon have HA support:

- :doc:`/postgresql/doc/index` server

The following states will soon have HA and HP support:

- :doc:`/graphite/doc/index`: Statistic and graphics
- :doc:`/graylog2/doc/index` centralized logging
- :doc:`/mongodb/doc/index` NoSQL database
- :doc:`/sentry/doc/index`: error notification and reporting

Once :doc:`/salt/master/doc/index` supports properly multi-master, the state
will support it.

Evolution
---------

The states in this repository are continously improved, fixed, updated (to catch
new version of OSS release). Each states regularly gains additional monitor
checks to verify the health of the application.

New states will be added as well.

Uninstallation of components
----------------------------

All the states come with its uninstall equivalent. These are required for
testing purpose. But they're also useful to undo some changes. They're called
"absent" states and they have the standard absent name. Example:
:doc:`/postgresql/doc/index` database server state is ``postgresql.server`` and
the uninstallation state is ``postgresql.server.absent``.

Unlike the states that install or create something that often include and
requires other state, the absent only remove itself. I don't try to uninstall
its dependencies. To revert entirely a server into its original form before
a component had been installed might require to run a lot of other absent
states.

Roles
-----

As explained in the philosophy section, states of that repository don't
hold any business specifics logic.

Who's in charge of integrate that states repository need to define its own
*roles* list in its own state repository.

Roles are simple human understandable definition of what servers can do in,
here is an example list:

- ``monitoring`` server
- ``database`` server
- ``webapp`` (server)
- ``frontend``
- ``backend``
- Developer ``sandbox``
- ``infra`` server that run all the infrastructure support tools

Or simply borrows the name of the low-level state:

- :doc:`/shinken/doc/index` monitoring host
- :doc:`/elasticsearch/doc/index` node

Then, for each role, who's responsible to integration this repository states
to the business requirements need to create one state file per role.
And they need to be under the ``roles`` folder, so the ``frontend`` role will be
in ``roles/frontend/init.sls`` file.
Why not ``roles/frontend.sls`` file? Because it might need additional
configuration files and all roles need to have its ``absent.sls`` file too. So,
there will be a ``roles/frontend/absent.sls`` file as well.

Role state file contains the specific such as: change DNS value of
``www.example.com`` to point to this server IP address if all lower-level
states had been applied succesfully.
Or use this other config file instead of the one that was in **common**
repository.
