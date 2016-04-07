{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

elasticsearch:
  service:
    - dead
    - enable: False
  process:
    - wait_for_dead
    - timeout: 60
    - name: '\-Delasticsearch'
    - require:
      - service: elasticsearch
  pkg:
    - purged
    - require:
      - process: elasticsearch

{% if grains['cpuarch'] == 'i686' %}
/usr/lib/jvm/java-7-openjdk:
  file:
    - absent
    - require:
      - pkg: elasticsearch
{% endif %}

{% for filename in ('/etc/default/elasticsearch', '/etc/elasticsearch', '/etc/nginx/conf.d/elasticsearch.conf') %}
{{ filename }}:
  file:
    - absent
    - require:
      - process: elasticsearch
{% endfor %}

/etc/elasticsearch/nginx_basic_auth:
  file:
    - absent
    - require:
      - process: elasticsearch
