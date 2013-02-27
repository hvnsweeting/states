{# no graphite server, put some random IP #}
graphite_address: 10.0.0.1
{# just put some IP, even if shinken poller are running on this host #}
shinken_pollers:
  - 127.0.0.1

graylog2_address: 127.0.0.1

hostname: {{ grains['id'] }}

uwsgi:
  repository: git://github.com/bclermont/uwsgi.git
  version: 1.4.3-patched

ubuntu_mirror: mirror.anl.gov/pub/ubuntu

message_do_not_modify: Salt managed file, any changes might be lost.

nginx:

debug: False

elasticsearch:
  version: 0.19.11
  md5: 4028d34c80fb4da94846c401fdc56589
  heap_size: 200m
  cluster:
    name: {{ grains['id'] }}
    nodes:
      {{ grains['id'] }}:
        private: 127.0.0.1
        public: 127.0.0.1

graylog2:
  elasticsearch: 127.0.0.1
  server:
    version: 0.9.6p1
    checksum: md5=499ae16dcae71eeb7c3a30c75ea7a1a6
  web:
    version: 0.9.6p1
    checksum: md5=f7b49a5259781a5a585cf7ee406e35c6
    hostnames:
      - {{ salt['network.interfaces']()['eth0']['inet'][0]['address'] }}
    port: 8000
    email:
      {# this will surely won't work #}
      method: smtp
      server: smtp.gmail.com
      user: user@whatever.com
      from: user@whatever.com
      port: 587
      password: xxx
      tls: True
    workers: 1
