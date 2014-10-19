{#-
Copyright (c) 2014, Hung Nguyen Viet
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Author: Hung Nguyen Viet <hvnsweeting@gmail.com>
Maintainer: Hung Nguyen Viet <hvnsweeting@gmail.com>
#}
include:
  - sslyze

test_sslyze_with_gmail:
  cmd:
    - run
{#- use --set= as it's not yet linked to any formula and check yet  #}
    - name: '/usr/lib/nagios/plugins/check_ssl_configuration.py --set=''{"host": "mail.google.com"}'''
    - require:
      - sls: sslyze

{%- macro test_sslyze(formula, pillar_prefix=None, domain_name=None) -%}
    {%- if not pillar_prefix -%}
        {%- set pillar_prefix = formula -%}
    {%- endif -%}
    {%- if not domain_name -%}
        {%- set domain_name = salt['pillar.get'](pillar_prefix + ':hostnames', ['127.0.0.1'])[0] -%}
    {%- endif -%}
    {%- if salt['pillar.get'](pillar_prefix + ':ssl', False) %}
{{ formula }}_ssl_configuration:
  monitoring:
    - run_check
    - accepted_failure: 'sslscore is 0 (FAILED - Certificate does NOT match alerts.local)'
    - require:
      - cmd: test_cron_d
    {%- endif -%}
{%- endmacro %}
