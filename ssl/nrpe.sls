{#- Usage of this is governed by a license that can be found in doc/license.rst -#}
{%- set use_letsencrypt = salt['pillar.get']('ssl:letsencrypt_admin_email', None) %}

include:
{%- if use_letsencrypt %}
  - acmetool.nrpe
{%- endif %}
  - apt.nrpe
  - openssl.nrpe
  - sslyze.nrpe
