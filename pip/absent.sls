{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{% set version='1.5.2' %}

{{ opts['cachedir'] }}/pip:
  file:
    - absent

{#
 Only during integration test, we don't want to wipe PIP cache for future usage.
 #}
{% if not salt['pillar.get']('__test__', False) %}
/var/cache/pip:
  file:
    - absent
{% endif %}

{{ salt['user.info']('root')['home'] }}/.pip:
  file:
    - absent

{{ salt['user.info']('root')['home'] }}/.pydistutils.cfg:
  file:
    - absent

/etc/pip.conf:
  file:
    - absent
{#
  Can't uninstall the following as they're used elsewhere
python-setuptools:
  pkg:
    - purged
#}
