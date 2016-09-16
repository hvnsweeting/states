{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set is_test = salt['pillar.get']('__test__', False) %}
{%- set version = "1.0.1" %}
{% set roundcubedir = "/usr/local/roundcubemail-" + version %}

{%- if is_test %}
php5-pgsql:
  pkg:
    - purged

roundcube_password_plugin_ldap_driver_dependency:
  pkg:
    - purged
    - pkgs:
      - php5-cgi
      - php-net-ldap2
{%- endif %}

{{ roundcubedir }}:
  file:
    - absent

/etc/nginx/conf.d/roundcube.conf:
  file:
    - absent

roundcube:
  user:
    - absent
  file:
    - absent
    - name: /var/lib/roundcube
    - require:
      - user: roundcube
