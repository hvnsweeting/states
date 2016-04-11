{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'nrpe/passive.jinja2' import passive_check with context %}
include:
  - apt.nrpe
  - erlang.nrpe
  - nrpe
  - rsyslog.nrpe

{{ passive_check('couchdb') }}

extend:
  nsca-erlang:
    file:
      - context:
          use_epmd: False
  erlang-monitoring:
    monitoring:
      - context:
          use_epmd: False
