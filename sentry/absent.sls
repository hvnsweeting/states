{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from "upstart/absent.sls" import upstart_absent with context -%}
{{ upstart_absent('sentry-celery') }}

sentry-uwsgi:
  file:
    - absent
    - name: /etc/uwsgi/sentry.yml
    - require:
      - file: /etc/nginx/conf.d/sentry.conf

/etc/sentry.conf.py:
  file:
    - absent
    - require:
      - file: sentry-uwsgi

/usr/local/sentry:
  file:
    - absent
    - require:
      - file: sentry-uwsgi

/etc/nginx/conf.d/sentry.conf:
  file:
    - absent

/var/lib/deployments/sentry:
  file:
    - absent

/etc/cron.daily/sentry-cleanup:
  file:
    - absent

{{ opts['cachedir'] }}/pip/sentry:
  file:
    - absent
