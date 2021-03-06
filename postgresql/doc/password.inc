:doc:`/postgresql/doc/index` user password.

.. note::

  If for any reason the password need to be retrieved after installation,
  use the custom salt module ``password.pillar`` and specify
  the pillar key name in format ``path:db:password``.

Default: ``None`` - auto generated by Salt.
