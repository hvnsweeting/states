include:
  - go

golint:
  cmd:
    - run
    - name: go get -u github.com/golang/lint/golint
    - env:
        GOPATH: "/var/lib/go"
    - require:
      - cmd: go_state_api

gocov:
  cmd:
    - run
    - name: go get -u github.com/hvnsweeting/gocov/...
    - env:
        GOPATH: "/var/lib/go"
    - require:
      - cmd: go_state_api

gocov_xml:
  cmd:
    - run
    - name: go get -u github.com/AlekSi/gocov-xml
    - env:
        GOPATH: "/var/lib/go"
    - require:
      - cmd: go_state_api

go_errcheck:
  cmd:
    - run
    - name: go get -u github.com/kisielk/errcheck
    - env:
        GOPATH: "/var/lib/go"
    - require:
      - cmd: go_state_api

go2xunit:
  cmd:
    - run
    - name: go get -u bitbucket.org/tebeka/go2xunit
    - env:
        GOPATH: "/var/lib/go"
    - require:
      - cmd: go_state_api

gobench2plot:
  cmd:
    - run
    - name: go get -u github.com/ryancox/gobench2plot
    - env:
        GOPATH: "/var/lib/go"
    - require:
      - cmd: go_state_api

go_protobuf_lint:
  cmd:
    - run
    - name: go get github.com/ckaznocha/protoc-gen-lint
    - env:
        GOPATH: "/var/lib/go"
    - require:
      - cmd: go_state_api

go_protoc:
  file:
    - directory
    - name: /usr/local/protoc
    - require:
      - file: /usr/local
  archive:
    - extracted
{# TODO: mirror when it is not beta #}
    - source: https://github.com/google/protobuf/releases/download/v3.0.0-beta-3/protoc-3.0.0-beta-3-linux-x86_64.zip
    - source_hash: md5=d1c68dbef61c44b3e2708f79429a9daa
    - name: /usr/local/protoc
    - archive_format: zip
    - if_missing: /usr/local/protoc/protoc
    - require:
      - file: go_protoc

go_protoc_binary:
  file:
    - managed
    - name: /usr/local/protoc/protoc
    - mode: 755
    - user: root
    - group: root
    - replace: False
    - require:
      - archive: go_protoc

go_protoc_symlink:
  file:
    - symlink
    - name: /usr/local/bin/protoc
    - target: /usr/local/protoc/protoc
    - require:
      - file: go_protoc_binary

protoc_gen_doc:
  pkgrepo:
    - managed
    - name: 'deb http://download.opensuse.org/repositories/home:/estan:/protoc-gen-doc/xUbuntu_14.04/ /'
    - key_url: salt://go/protoc_gen_doc.gpg
    - file: /etc/apt/sources.list.d/protoc-gen-doc.list
    - clean_file: True
    - require:
      - pkg: apt_sources
  pkg:
    - installed
    - name: protoc-gen-doc
    - require:
      - pkgrepo: protoc_gen_doc
      - cmd: apt_sources
