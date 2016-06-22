{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'apparmor/macro.jinja2' import profile_absent with context %}

{{ profile_absent('pptpd', '/usr/sbin/pptpd') }}
