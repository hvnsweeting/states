{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

rsyslog:
  pkg:
    - purged
    - require:
      - service: rsyslog
  file:
    - absent
    - name: /etc/rsyslog.conf
    - require:
      - pkg: rsyslog
  service:
    - dead
{# only for ubuntu precise #}
  cmd:
    - run
    - name: 'apt-key del 431533D8'
    - onlyif: apt-key list | grep -q 431533D8
  pkgrepo:
    - absent
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/rsyslog/7.4.4 {{ grains['oscodename'] }} main
{%- else %}
    - name: deb http://archive.robotinfra.com/mirror/rsyslog/7.4.4 {{ grains['oscodename'] }} main
{%- endif %}

/etc/apt/sources.list.d/tmortensen-rsyslogv7-{{ grains['oscodename'] }}.list:
  file:
    - absent
    - require:
      - pkgrepo: rsyslog
{# end for ubuntu precise #}

/etc/rsyslog.d:
  file:
    - absent
    - require:
      - service: rsyslog

{# only for ubuntu precise #}
/etc/apt/sources.list.d/rsyslogv7.list:
  file:
    - absent
{# end for ubuntu precise #}

/var/spool/rsyslog:
  file:
    - absent
    - require:
      - pkg: rsyslog

/var/log/lastlog:
  file:
    - absent
    - require:
      - pkg: rsyslog

rsyslog_absent_mail_logs:
  cmd:
    - run
    - name: rm -f /var/log/mail.*
    - require:
      - service: rsyslog
