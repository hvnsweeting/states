{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{% from 'upstart/rsyslog.jinja2' import manage_upstart_log with context %}
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- set mirror = files_archive|replace('https://', 'http://') ~ "/mirror/syncthing"
    if files_archive else "http://archive.robotinfra.com/mirror/syncthing" %}
{%- set version = "0.12.7" %}
{%- set repo = mirror ~ "/" ~ version %}
{%- set ssl = salt["pillar.get"]("syncthing:ssl", False) %}
{%- set hostnames = salt["pillar.get"]("syncthing:hostnames", []) %}

include:
  - apt
  - rsyslog
{%- if hostnames %}
  - nginx
{%- endif %}
{%- if ssl %}
  - ssl
{%- endif %}

/etc/syncthing:
  file:
    - directory
    - user: syncthing
    - group: syncthing
    - mode: 700
    - require:
      - user: syncthing

syncthing:
  user:
    - present
    - home: /var/lib/syncthing
    - shell: /bin/false
  pkgrepo:
    - managed
    - name: deb {{ repo }} syncthing release
    - key_url: salt://syncthing/key.gpg
    - file: /etc/apt/sources.list.d/syncthing.list
    - clean_file: True
    - require:
      - pkg: apt_sources
  pkg:
    - latest
    - name: syncthing
    - require:
      - pkgrepo: syncthing
  file:
    - managed
    - name: /etc/init/syncthing.conf
    - template: jinja
    - source: salt://syncthing/upstart.jinja2
    - mode: 440
    - user: root
    - group: root
    - context:
        username: "admin"
        password: {{ salt["pillar.get"]("syncthing:password") }}
    - show_diff: False
    - require:
      - pkg: syncthing
      - user: syncthing
  service:
    - running
    - enable: True
    - require:
      - service: rsyslog
    - watch:
      - pkg: syncthing
      - file: syncthing

/var/lib/syncthing:
  file:
    - directory
    - user: syncthing
    - group: syncthing
    - mode: 750
    - require:
      - user: syncthing
    - watch_in:
      - service: syncthing

{%- if not salt['file.is_link']('/etc/syncthing/index-v0.11.0.db') %}
syncthing_move_old_index_dir_if_exist:
  cmd:
    - run
    - name: stop syncthing && mv /etc/syncthing/index-v0.11.0.db /var/lib/syncthing/index.db && start syncthing
    - require:
      - pkg: syncthing
      - file: /etc/syncthing
    - require_in:
      - file: syncthing_index_dir_symlink
      - file: /var/lib/syncthing/index.db
      - service: syncthing
{%- endif %}

/var/lib/syncthing/index.db:
  file:
    - directory
    - user: syncthing
    - group: syncthing
    - mode: 750
    - require:
      - user: syncthing
    - watch_in:
      - service: syncthing

syncthing_index_dir_symlink:
  file:
    - symlink
    - name: /etc/syncthing/index-v0.11.0.db
    - target: /var/lib/syncthing/index.db
    - mode: 444
    - user: syncthing
    - group: syncthing
    - require:
      - file: /etc/syncthing
      - file: /var/lib/syncthing/index.db
    - watch_in:
      - service: syncthing

/etc/syncthing/cert.pem:
  file:
    - managed
    - mode: 444
    - user: syncthing
    - group: syncthing
    - contents_pillar: syncthing:cert
    - require:
      - file: /etc/syncthing
    - watch_in:
      - service: syncthing

/etc/syncthing/key.pem:
  file:
    - managed
    - mode: 400
    - user: syncthing
    - group: syncthing
    - contents_pillar: syncthing:key
    - require:
      - file: /etc/syncthing
    - watch_in:
      - service: syncthing

{%- set folders = salt["pillar.get"]("syncthing:folders", {}) %}
{%- for config in folders.itervalues() %}
  {%- do config["devices"].append(grains["id"]) %}
{%- endfor %}
{%- do folders.update({"default": {"path": "/var/lib/syncthing/Sync", "devices": [grains["id"]]}}) %}
{%- set devices = salt["pillar.get"]("syncthing:devices", {}) %}
{%- do devices.update({grains["id"]: {"id": salt["pillar.get"]("syncthing:device_id")}}) %}

{%- for id, config in folders.iteritems() %}
  {%- set path = config.get("path", "/var/lib/syncthing/" + id) %}
syncthing_shared_directory_{{ path }}:
  file:
    - directory
    - name: {{ path }}
    - user: syncthing
    - group: syncthing
    - mode: 750
    - require:
      - user: syncthing
    - require_in:
      - service: syncthing
{%- endfor %}

/etc/syncthing/config.xml:
  file:
    - managed
    - template: jinja
    - source: salt://syncthing/config.jinja2
    - mode: 400
    - user: syncthing
    - group: syncthing
    - context:
        folders: {{ folders }}
        devices: {{ devices }}
    - require:
      - file: /etc/syncthing/cert.pem
      - file: /etc/syncthing/key.pem
    - watch_in:
      - service: syncthing

{{ manage_upstart_log('syncthing', severity="info") }}

/etc/nginx/conf.d/syncthing.conf:
  file:
{%- if hostnames %}
    - managed
    - source: salt://syncthing/nginx.jinja2
    - template: jinja
    - user: root
    - group: www-data
    - mode: 440
    - context:
        appname: syncthing
        hostnames: {{ hostnames }}
    - require:
      - pkg: nginx
      - service: syncthing
  {%- if ssl %}
      - cmd: ssl_cert_and_key_for_{{ ssl }}
  {%- endif %}
    - watch_in:
      - service: nginx
{%- else %}
    - absent
{%- endif %}

{%- if hostnames %}
  {%- if ssl %}
extend:
  nginx.conf:
    file:
      - context:
          ssl: {{ ssl }}
  nginx:
    service:
      - watch:
        - cmd: ssl_cert_and_key_for_{{ ssl }}
  {%- endif %}
{%- endif %}

{%- for file in ("cert.pem",
                 "key.pem",
                 "config.xml",
                 "https-cert.pem",
                 "https-key.pem",
                 "index-v0.11.0.db",
)
%}
syncthing_cleanup_{{ file }}:
  file:
    - name: /var/lib/syncthing/{{ file }}
    - absent
    - require:
      - service: syncthing
{%- endfor %}
