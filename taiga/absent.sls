{#- Usage of this is governed by a license that can be found in doc/license.rst -#}
taiga:
  file:
    - absent
    - name: /usr/local/taiga

taiga_symlink:
  file:
    - absent
    - name: /usr/local/taiga-back

taiga_additional_requirements:
  file:
    - absent
    - name: {{ opts['cachedir'] }}/pip/taiga

taiga-uwsgi:
  file:
    - absent
    - name: /etc/uwsgi/taiga.yml

/usr/local/taiga/manage:
  file:
    - absent

/etc/nginx/conf.d/taiga.conf:
  file:
    - absent

/var/lib/deployments/taiga:
    file:
    - absent
