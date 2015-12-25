gnupg:
  pkg:
    - purged
    - pkgs:
      {#- - gnupg #} {#- can't remove, apt requires it #}
      - python-gnupg

{%- for user in salt['pillar.get']('gnupg:users', {}) %}
  {%- set userinfo = salt['user.info'](user) %}
  {%- if userinfo %}
gnupg_absent_key_for_user_{{ user }}:
  file:
    - absent
    - name: {{ userinfo['home'] }}/.gnupg
  {%- endif %}
{%- endfor %}
