..
   Author:  Viet Hung Nguyen <hvn@robotinfra.com>
   Maintainer: Viet Hung Nguyen <hvn@robotinfra.com>

Discourse
=========

Discourse is the 100% open source discussion platform built for the next decade
of the Internet. It works as:

- a mailing list
- a discussion forum
- a long-form chat room

..  https://www.discourse.org/faq/

Links
-----

* `Homepage <https://www.discourse.org/>`_

Related Formulas
----------------

* :doc:`/apt/doc/index`
* :doc:`/docker/doc/index`

Usage
-----

Discourse must be used with :doc:`/postgresql/doc/index` 9.3.
Set the version through pillar value :ref:`pillar-postgresql-version`.

Administrator must set :ref:`pillar-postgresql-shared_buffers` to a max of 25%
of the total memory. On 1GB installs set to 128MB (to leave room for other
processes) on a 4GB instance you may raise to 1GB.

It's also need to set :ref:`pillar-postgresql-work_mem` at least 10MB, for a
3GB install 40MB is a good default this improves sorting performance, but adds
memory usage per-connection.

Consult https://github.com/discourse/discourse_docker/blob/master/samples/standalone.yml
for more details.

Content
-------

.. toctree::
    :glob:

    *
