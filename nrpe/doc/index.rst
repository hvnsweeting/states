..
   Author: Bruno Clermont <bruno@robotinfra.com>
   Maintainer: Viet Hung Nguyen <hvn@robotinfra.com>

NRPE
====

Introduction
------------

The :doc:`index` addon is designed to allow you to execute Nagios plugins on
remote Linux/Unix machines. The main reason for doing this is to allow Nagios
to monitor "local" resources (like CPU load, memory usage, etc.) on remote
machines. Since these public resources are not usually exposed to external
machines, an agent like :doc:`index` must be installed on the remote Linux/Unix
machines.

Please check
`the following <http://nagios.sourceforge.net/docs/nrpe/NRPE.pdf>`_
page 1 and 2 for more details.

Links
-----

* `Nagios
  <http://exchange.nagios.org/directory/Addons/Monitoring-Agents/
  NRPE--2D-Nagios-Remote-Plugin-Executor/details>`_
* `Wikipedia <http://en.wikipedia.org/wiki/Nagios#NRPE>`_

Related Formula
---------------

* :doc:`/apt/doc/index`

Content
-------

.. toctree::
    :glob:

    *
