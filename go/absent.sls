{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

go:
  file:
    - absent
    - name: /usr/local/go

{%- for f in ('go', 'gofmt', 'godoc') %}
go_{{ f }}:
  file:
    - absent
    - name: /usr/local/bin/{{ f }}
{%- endfor %}
