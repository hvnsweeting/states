..
   Author: Bruno Clermont <bruno@robotinfra.com>
   Maintainer: Viet Hung Nguyen <hvn@robotinfra.com>

Backup Client
=============

Formula under this directory provides scripts to ease backup data to multiple
different backup solutions, such as:

- :doc:`/backup/client/s3/doc/index` for backup data to :ref:`glossary-S3`.
- :doc:`/backup/client/scp/doc/index` for backup data to
  :doc:`/ssh/server/doc/index` setup by :doc:`/backup/server/doc/index`.
- :doc:`/backup/client/noop/doc/index` used for testing purpose only, ignore
  it.

.. warning::

  Only one client can be defined per :doc:`/salt/minion/doc/index`/host.

Contents:

.. toctree::
    :glob:

    *

    ../s3/doc/index
    ../scp/doc/index
    ../noop/doc/index
    ../local/doc/index
