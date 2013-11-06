{#-
Copyright (C) 2013 the Institute for Institutional Innovation by Data
Driven Design Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE  MASSACHUSETTS INSTITUTE OF
TECHNOLOGY AND THE INSTITUTE FOR INSTITUTIONAL INNOVATION BY DATA
DRIVEN DESIGN INC. BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the names of the Institute for
Institutional Innovation by Data Driven Design Inc. shall not be used in
advertising or otherwise to promote the sale, use or other dealings
in this Software without prior written authorization from the
Institute for Institutional Innovation by Data Driven Design Inc.

Author: Hung Nguyen Viet <hvnsweeting@gmail.com>
Maintainer: Hung Nguyen Viet <hvnsweeting@gmail.com>

Nagios NRPE check for moinmoin.
-#}
include:
  - apt.nrpe
  - nginx.nrpe
  - nrpe
  - pip.nrpe
  - python.dev.nrpe
  - rsyslog.nrpe
{% if salt['pillar.get']('moinmoin:ssl', False) %}
  - ssl.nrpe
{% endif %}
  - uwsgi.nrpe
  - virtualenv.nrpe

/etc/nagios/nrpe.d/moinmoin.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://uwsgi/nrpe/instance.jinja2
    - require:
      - pkg: nagios-nrpe-server
    - context:
      deployment: moinmoin
      workers: {{ salt['pillar.get']('moinmoin:workers', '2') }}
      cheaper: {{ salt['pillar.get']('moinmoin:cheaper', False) }}
    - require:
      - pkg: nagios-nrpe-server

/etc/nagios/nrpe.d/moinmoin-nginx.cfg:
  file:
    - managed
    - template: jinja
    - user: nagios
    - group: nagios
    - mode: 440
    - source: salt://nginx/nrpe/instance.jinja2
    - require:
      - pkg: nagios-nrpe-server
    - context:
      deployment: moinmoin
      domain_name: {{ pillar['moinmoin']['hostnames'][0] }}
      http_uri: /StartingPage?action=login
{%- if salt['pillar.get']('moinmoin:ssl', False) %}
      https: True
    {%- if salt['pillar.get']('moinmoin:ssl_redirect', False) %}
      http_result: 301 Moved Permanently
    {%- endif -%}
{%- endif %}

extend:
  nagios-nrpe-server:
    service:
      - watch:
        - file: /etc/nagios/nrpe.d/moinmoin.cfg
        - file: /etc/nagios/nrpe.d/moinmoin-nginx.cfg
