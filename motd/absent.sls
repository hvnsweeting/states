{#-
Use of this source code is governed by a BSD license that can be found
in the doc/license.rst file.


Undo motd state.
-#}
/etc/motd.tail:
  file:
    - absent

/etc/motd:
  file:
    - absent
