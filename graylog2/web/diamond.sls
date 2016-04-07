{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{% set version = '1.3.4' %}

include:
  - diamond
  - nginx.diamond
  - rsyslog.diamond

graylog2_web_diamond_resource:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[graylog2-web]]
        cmdline = java.+graylog\-web\-interface\-{{ version }}\.jar
