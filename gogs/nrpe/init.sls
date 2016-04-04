{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'nrpe/passive.jinja2' import passive_check with context %}
include:
  - apt.nrpe
  - git.nrpe
  - git.server.nrpe
  - nginx.nrpe
  - postgresql.server.nrpe
  - ssh.client.nrpe
{%- if salt['pillar.get']('gogs:ssl', False) %}
  - ssl.nrpe
{%- endif %}

{{ passive_check('gogs') }}
