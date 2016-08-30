php-fpm:
  service:
    - dead
    - name: php5-fpm
  pkg:
    - purged
    - name: php5-fpm
    - require:
      - service: php5-fpm
