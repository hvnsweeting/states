Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/apt/doc/index` :doc:`/apt/doc/pillar`
- :doc:`/mongodb/doc/index`
- :doc:`/rsyslog/doc/index` :doc:`/rsyslog/doc/pillar`

.. note::

   :doc:`index` will act as a :doc:`/elasticsearch/doc/index` node, it requires
   :ref:`pillar-elasticsearch-cluster-nodes` to be set as a normal
   :doc:`/elasticsearch/doc/index` node.

Mandatory
---------

Example::

  graylog2:
    admin_password: 06f8a1541ca80cfe08fe6fe7576c7e37a3480e8d1a12486fc9d85880478ab2cb

.. _pillar-graylog2-admin_password:

graylog2:admin_password
~~~~~~~~~~~~~~~~~~~~~~~

Graylog2 admin password.

.. _pillar-graylog2-password_secret:

graylog2:password_secret
~~~~~~~~~~~~~~~~~~~~~~~~

To secure/pepper the stored user passwords, use at least 64
characters.

.. warning::

   changing this value will makes all existing users unable to login. In case
   old value is lost, use administrator password defined in
   :ref:`pillar-graylog2-admin_password` to reset password for existing users.

Optional
--------

.. _pillar-graylog2-admin_username:

graylog2:admin_username
~~~~~~~~~~~~~~~~~~~~~~~

Admin user's username.

Default: ``admin``.

.. _pillar-graylog2-rest_listen_uri:

graylog2:rest_listen_uri
~~~~~~~~~~~~~~~~~~~~~~~~

REST API listen URI. Must be reachable by other
:doc:`index` nodes if you run a cluster.

Default: ``http://127.0.0.1:12900``.

.. _pillar-graylog2-rest_transport_uri:

graylog2:rest_transport_uri
~~~~~~~~~~~~~~~~~~~~~~~~~~~

REST API transport address. If not set, the value is same as
`graylog2:rest_listen_uri`_.

Default: use same value as `graylog2:rest_listen_uri`_ (``None``).

.. _pillar-graylog2-rotation_strategy:

graylog2:rotation_strategy
~~~~~~~~~~~~~~~~~~~~~~~~~~

Value of rotation strategy.
The strategy is used to determine when to rotate the currently active
write index.

Valid values are "count", "size" and "time".

- If strategy is "count", you must use
  :ref:`pillar-graylog2-max_docs_per_index` to configure.

- If strategy is "size", you must use
  :ref:`pillar-graylog2-max_size_per_index` to configure.

- If strategy is "time", you must
  use :ref:`pillar-graylog2-max_time_per_index` to configure.

Default: use ``count`` strategy.

.. _pillar-graylog2-max_number_of_indices:

graylog2:max_number_of_indices
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

How many indices to have in total.
If this number is reached, the oldest index will be deleted.

Default: use ``20`` indices.

.. _pillar-graylog2-shards:

graylog2:shards
~~~~~~~~~~~~~~~

The number of shards (a shard is a single `Lucene
<http://lucene.apache.org/core/>`_ instance, see
:doc:`/elasticsearch/doc/index` `glossary
<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/glossary.html>`_)
for your indices.

Default: use ``4`` shards per index.

.. _pillar-graylog2-replicas:

graylog2:replicas
~~~~~~~~~~~~~~~~~

Number of :doc:`/elasticsearch/doc/index` replicas per index.

Default: don't use replica (``0``).

.. _pillar-graylog2-processbuffer_processors:

graylog2:processbuffer_processors
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The number of parallel running processors.

Default: use ``5`` parallel processbuffer processors.

.. _pillar-graylog2-outputbuffer_processors:

graylog2:outputbuffer_processors
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The number of parallel running processors.

Default: use ``3`` parallel outputbuffer processors.

.. _pillar-graylog2-processor_wait_strategy:

graylog2:processor_wait_strategy
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Wait strategy describing how buffer processors wait on a cursor sequence.

Possible types:

yielding
  Compromise between performance and CPU usage.

sleeping
  Compromise between performance and CPU usage. Latency spikes can occur after quiet periods.

blocking
  High throughput, low latency, higher CPU usage.

busy_spinning
  Avoids syscalls which could introduce latency jitter. Best when
  threads can be bound to specific CPU cores.

Default: ``blocking``.

.. _pillar-graylog2-ring_size:

graylog2:ring_size
~~~~~~~~~~~~~~~~~~

Size of internal ring buffers. Raise this if raising
:ref:`pillar-graylog2-processbuffer_processors` does not help anymore.

Default: ``65536``.

.. _pillar-graylog2-heap_size:

graylog2:heap_size
~~~~~~~~~~~~~~~~~~

The size of `heap
<http://en.wikipedia.org/wiki/Java_virtual_machine#Heap>`_ give for
JVM.

.. note::

   This value must be adjusted bases on memory size of server. Also see
   :ref:`pillar-graylog2-web-heap_size`, as both :doc:`/graylog2/web/doc/index`
   and :doc:`index` will be installed in same machine.

Default: use JVM default (``False``).

graylog2:streams
~~~~~~~~~~~~~~~~

List of :doc:`/graylog2/doc/index` streams to created.

Format::

  graylog2:
    streams:
      {{ stream_name }}:
        rules:
          - field: {{ field_name }}
            value: {{ value }}
            inverted: {{ True or False }}
            type: {{ rule type }}
          - ...
        receivers:
          - {{ email }}
          - ...
        receivers_type: {{ "emails" or "users" }}
        alert_grace: 10

Only ``{{ stream_name }}`` is mandatory.

Default: don't send alert emails (``{}``).

Conditional
-----------

Example1::

  graylog2:
    rotation_strategy: count
    max_docs_per_index: 2000000
    max_number_of_indices: 5

.. _pillar-graylog2-max_docs_per_index:

graylog2:max_docs_per_index
~~~~~~~~~~~~~~~~~~~~~~~~~~~

How many log messages to keep per index.

Default: keep ``20000000`` log messages per index.

.. note::

  Only used if the :ref:`pillar-graylog2-rotation_strategy` is set
  to ``count``.

Example2::

  graylog2:
    rotation_strategy: size
    max_size_per_index: 1073741824
    max_number_of_indices: 2

.. _pillar-graylog2-max_size_per_index:

graylog2:max_size_per_index
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Maximum size of a index.

Default: ``1GB``.

.. note::

  Only used if the :ref:`pillar-graylog2-rotation_strategy` is set
  to ``size``.

Example3::

  graylog2:
    rotation_strategy: time
    max_time_per_index: id
    max_number_of_indices: 14

.. _pillar-graylog2-max_time_per_index:

graylog2:max_time_per_index
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Maximum time before a new index is being created.

Default:  1 day ``1d``.

.. note::

  Only used if the :ref:`pillar-graylog2-rotation_strategy`
  is set to ``time``.
