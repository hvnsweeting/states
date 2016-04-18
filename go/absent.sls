{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

go:
  file:
    - absent
    - name: /usr/local/go

go_path:
  file:
    - absent
    - name: /var/lib/go

{%- for f in ('go', 'gofmt', 'godoc') %}
go_{{ f }}:
  file:
    - absent
    - name: /usr/local/bin/{{ f }}
{%- endfor %}
