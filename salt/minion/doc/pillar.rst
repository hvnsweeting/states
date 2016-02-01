Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/rsyslog/doc/index` :doc:`/rsyslog/doc/pillar`

Optional
--------

Example::

  salt:
    highstate: False
    master: 2.3.4.5

.. _pillar-salt-highstate:

salt:highstate
~~~~~~~~~~~~~~

.. TODO: replace highstate with link to salt doc for this module

Allows :doc:`/salt/master/doc/index` calls `state.highstate
<https://docs.saltstack.com/en/latest/ref/modules/all/
salt.modules.state.html#salt.modules.state.highstate>`_ against this minion
daily through its :doc:`/cron/doc/index` job.

Default: Allow ``highstate`` every day (``True``).

.. _pillar-salt-master:

salt:master
~~~~~~~~~~~

Address of :doc:`/salt/master/doc/index`.

If set to ``False`` means this minion will run in master-less (local) mode.

Default: ``False``.

.. _pillar-salt-extra:

salt:extra
~~~~~~~~~~

Dictionary of extra configuration add to :doc:`index` config file. E.g::

  salt:
    extra:
      jenkins.username: myjenkins
      jenkins.token: 123124ssafd
      jenkins.base_url: 'https://test.jenkins.io'

Default: ``{}``.
