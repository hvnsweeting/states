include:
  - apt

{#- Change shell of predefined user (UID <= 99) from `/bin/sh` to `/usr/sbin/nologin` #}

base-passwd:
  pkg:
    - installed
    - require:
      - cmd: apt_sources
  cmd:
    - wait
    - name: update-passwd
    - watch:
      - file: /usr/share/base-passwd/passwd.master

/usr/share/base-passwd/passwd.master:
  file:
    - managed
    - source: salt://users/config.jinja2
    - user: root
    - group: root
    - mode: 440
    - require:
      - pkg: base-passwd

{%- set users = salt["pillar.get"]("users", {}) %}
{%- set reserved_keys = ("authorized_keys") %}
{%- set local = {"auth_keys_contents": []} %}

{%- for user, user_data in users.iteritems() %}
user_{{ user }}:
  user:
    - present
    - name: {{ user }}
  {%- for key, val in user_data.iteritems() %}
    {%- if key not in reserved_keys %}
    - {{ key }}: {{ val }}
    {%- endif %}
  {%- endfor %}

  {%- set auth_keys = user_data["authorized_keys"]|default([]) %}
  {%- for key in auth_keys %}
    {%- set key_type, key_content = key.split()[:2] %}
user_{{ user }}_add_authorized_key_{{ loop.index }}:
  ssh_auth:
    - present
    - name: {{ key_content }}
    - user: {{ user }}
    - enc: {{ key_type }}
    - require:
      - user: user_{{ user }}
  {%- endfor %}

  {#- cleanup existed but undefined auth_keys #}
  {%- set existed_auth_keys = salt["ssh.auth_keys"](user) %}
  {%- for key in auth_keys %}
    {%- do local.auth_keys_contents.append(key.split()[1]) %}
  {%- endfor %}
  {% for key, key_data in existed_auth_keys.iteritems() %}
    {% if key not in local.auth_keys_contents %}
user_{{ user }}_delete_unmanaged_authorized_key_{{ loop.index }}:
  ssh_auth:
    - absent
    - name: {{ key }}
    - user: {{ user }}
    - enc: {{ key_data["enc"] }}
    - require:
      - user: user_{{ user }}
    {%- endif %}
  {%- endfor %}

{%- endfor %}
