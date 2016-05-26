Pillar
======

.. include:: /doc/include/add_pillar.inc

Optional
--------

Example::

  users:
    diego:
      groups:
        - group 1
        - group 2
      fullname: Diego Maradona
      authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDB+hcS+d/V0cmEDX9zv07jXcH+b5DB4YD9ptx0kVtpfkQWc+TtYH/eY2jmTXUZWVx+kfn5qDI3Ojq9jRgfgM0tuICqTW78Vi2P4Qd5ektFkkAa9ERhhZRMzi0tbpQdyOQxEkflh3Upmuwm+im9Y4TdWNvVO3cM+DOCH1JNpEgh5OGo52/Tq/FUgzt750Ls1/QPzbmkgUYd9SmEknrS/dHm9XRm5D0RumQzW75CniuyZEx+Gn/C/+h+mHapBCXizUZEK9+y7er9MOmHTZ5Er9tb/bc6k7cQYXVzIGqLm8ENV1SYeSwxuTsPrvTsBGHqURBAnz3OllQD2yws5XmmIJ2L

.. _pillar-users:

users
~~~~~

Dictionary contains data of normal users to manage.

Format::

  users:
    {{ username }}:
      {{ option1 }}: {{ value1 }}
      {{ option2 }}: {{ value2 }}
      authorized_keys:
        - {{ public ssh key }}


For list of valid option/value pairs, consult `user.present
<http://docs.saltstack.com/en/latest/ref/states/all/salt.states.user.html#salt.states.user.present>`_
module documentation.

Default: doesn't manage any user (``{}``).
