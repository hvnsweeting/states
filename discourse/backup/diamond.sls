{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - backup.diamond
  - cron.diamond

{#- salt can't require sls with no state #}
discourse_backup_diamond:
  cmd:
    - wait
    - name: /bin/echo 'this state does nothing'
