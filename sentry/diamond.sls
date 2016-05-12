{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- from 'diamond/macro.jinja2' import uwsgi_diamond with context %}
{%- call uwsgi_diamond('sentry') %}
- cron.diamond
- memcache.diamond
- postgresql.server.diamond
- rsyslog.diamond
- redis.diamond
- statsd.diamond
{%- endcall %}

sentry_diamond_resources:
  file:
    - accumulated
    - name: processes
    - filename: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - require_in:
      - file: /etc/diamond/collectors/ProcessResourcesCollector.conf
    - text:
      - |
        [[sentry-worker]]
        cmdline = ^\[celeryd:
        [[sentry-beat]]
        cmdline = ^\[celery beat\]$
