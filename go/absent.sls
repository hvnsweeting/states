{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

go:
  file:
    - absent
    - name: /usr/local/go

go_protoc_dir:
  file:
    - absent
    - name: /usr/local/protoc

go_path:
  file:
    - absent
    - name: /var/lib/go

{%- for f in ('go', 'gofmt', 'godoc', 'protoc') %}
go_{{ f }}:
  file:
    - absent
    - name: /usr/local/bin/{{ f }}
{%- endfor %}

protoc_gen_doc:
  pkgrepo:
    - absent
    - file: /etc/apt/sources.list.d/protoc-gen-doc.list
  pkg:
    - purged
    - name: protoc-gen-doc
  cmd:
    - run
    - name: apt-key del 066C0892
    - onlyif: apt-key list | grep -q 066C0892
  file:
    - absent
    - name: /etc/apt/sources.list.d/protoc-gen-doc.list
