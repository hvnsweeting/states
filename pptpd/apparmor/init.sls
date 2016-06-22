{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'apparmor/macro.jinja2' import profile_managed with context %}

{{ profile_managed('pptpd', '/usr/sbin/pptpd') }}
