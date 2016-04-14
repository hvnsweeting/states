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
