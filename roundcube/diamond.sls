{#- Usage of this is governed by a license that can be found in doc/license.rst -#}
include:
  - diamond
  - nginx.diamond
  - php_fpm.diamond
  - postgresql.server.diamond
  - rsyslog.diamond

roundcube_diamond_just_avoid_empty_sls:
  module:
    - run
    - name: test.echo
    - text: test
