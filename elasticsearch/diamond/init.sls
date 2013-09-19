{#
 Diamond statistics for Elasticsearch
 TODO: Diamond + http://www.elasticsearch.org/guide/reference/modules/jmx/
 #}
{% set ssl = pillar['elasticsearch']['ssl']|default(False) %}
include:
  - diamond
  - cron.diamond
  - elasticsearch
{% if ssl %}
  - nginx.diamond
{% endif %}

elasticsearch_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[elasticsearch]]
        cmdline = .+java.+\-cp \:\/usr\/share\/elasticsearch\/lib\/elasticsearch\-.+\.jar

/etc/diamond/collectors/ElasticSearchCollector.conf:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 440
    - source: salt://elasticsearch/diamond/config.jinja2
    - require:
      - file: /etc/diamond/collectors

extend:
  diamond:
    service:
      - require:
        - service: elasticsearch
      - watch:
        - file: /etc/diamond/collectors/ElasticSearchCollector.conf
