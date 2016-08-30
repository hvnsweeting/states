include:
  - apt

php-fpm:
  pkg:
    - name: php5-fpm
    - installed
    - require:
      - cmd: apt_sources
  service:
    - running
    - name: php5-fpm
    - require:
      - pkg: php5-fpm
