{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

nagios-nrpe-server:
  pkg:
    - purged
    - pkgs:
      - nagios-nrpe-server
      - nagios-plugins-standard
      - nagios-plugins-basic
    - require:
      - service: nagios-nrpe-server
  service:
    - dead
    - enable: False
  user:
    - absent
    - name: nagios
    - require:
      - pkg: nagios-nrpe-server
      - service: nsca_passive
  group:
    - absent
    - name: nagios
    - require:
      - user: nagios-nrpe-server
  file:
    - absent
    - name: /var/lib/nagios
    - require:
      - pkg: nagios-nrpe-server

{#
 For some reason, purge nagios-nrpe-server Ubuntu package don't clean these.
 /var/run/nagios is $HOME of user nagios.
 So, when nagios-nrpe-server is uninstalled the first time the UID of this
 directory is changed to something else, once userdel nagios is executed.
 When nagios-nrpe-server is installed again, it can't write the PID file in
 /var/run/nagios. As the ownership is not for itself, it can't write the PID.
 This cause stopping the service to fail, as it can't find a PID.
#}
{% for dirname in ('/etc', '/var/run', '/usr/lib', '/usr/local') %}
{{ dirname }}/nagios:
  file:
    - absent
    - require:
      - user: nagios-nrpe-server
      - service: nsca_passive
      - pkg: nagios-nrpe-server
{% endfor %}

{%- from "upstart/absent.sls" import upstart_absent with context -%}
{{ upstart_absent('nsca_passive') }}

/usr/local/nagiosplugin:
  file:
    - absent
    - require:
      - service: nagios-nrpe-server
      - service: nsca_passive

/etc/sudoers.d/nrpe_oom:
  file:
    - absent
    - require:
      - service: nagios-nrpe-server
      - service: nsca_passive

/etc/sudoers.d/nrpe_disk:
  file:
    - absent
    - require:
      - service: nagios-nrpe-server
      - service: nsca_passive

/etc/cron.d/passive-checks-nrpe.cfg:
  file:
    - absent
    - require:
      - service: nagios-nrpe-server
      - service: nsca_passive

/etc/rsyslog.d/nrpe.conf:
  file:
    - absent
    - require:
      - service: nagios-nrpe-server
      - service: nsca_passive

{{ opts['cachedir'] }}/pip/nrpe:
  file:
    - absent

/etc/cron.hourly/nrpe-killer:
  file:
    - absent
