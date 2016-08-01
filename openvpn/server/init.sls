{#- Usage of this is governed by a license that can be found in doc/license.rst -#}
{% extends "openvpn/server/baseinit.sls" %}

{%- block openvpn_instance %}
{{ service_openvpn(instance, service_running=False) }}
{%- endblock openvpn_instance %}
