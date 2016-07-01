{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "upstart/absent.sls" import upstart_absent with context -%}
{{ upstart_absent('webdav') }}

/usr/local/webdav:
  file:
    - absent
    - require:
      - service: webdav

webdav_user:
  user:
    - absent
    - name: webdav
    - require:
      - service: webdav

/etc/webdav:
  file:
    - absent
    - require:
      - service: webdav

/var/lib/webdav:
  file:
    - absent
    - require:
      - service: webdav

/var/log/webdav:
  file:
    - absent
    - require:
      - service: webdav
