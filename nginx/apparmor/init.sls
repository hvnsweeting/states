{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'apparmor/macro.jinja2' import gen_profile with context %}

{{ gen_profile('nginx', 'usr.sbin.nginx') }}
