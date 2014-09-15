{#-
-*- ci-automatic-discovery: off -*-

Copyright (c) 2013, Bruno Clermont
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

Author: Bruno Clermont <patate@fastmail.cn>
Maintainer: Hung Nguyen Viet <hvnsweeting@gmail.com>

Remove Nagios NRPE check for PostgreSQL Server.
-#}
/etc/nagios/nrpe.d/postgresql-diamond.cfg:
  file:
    - absent

/etc/nagios/nrpe.d/postgresql.cfg:
  file:
    - absent

{%- from 'nrpe/passive.sls' import passive_absent with context %}
{{ passive_absent('postgresql.common') }}

/usr/lib/nagios/plugins/check_psql_encoding.py:
  file:
    - absent

/usr/local/nagios/src/check_postgres-2.21.0:
  file:
    - absent

/usr/lib/nagios/plugins/check_postgres:
  file:
    - absent

/etc/sudoers.d/nrpe_postgresql_common:
  file:
    - absent
