{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - diamond
  - nginx.diamond
  - postgresql.server.diamond
  - rsyslog.diamond

mattermost_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[mattermost]]
        cmdline = ^\/usr\/local\/mattermost\/bin\/platform
