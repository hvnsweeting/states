{%- from 'macros.jinja2' import dict_default with context %}
{% set users = salt["pillar.get"]("gnupg:users", {}) %}
include:
  - apt

gnupg:
  pkg:
    - latest
    - pkgs:
      - gnupg
      - python-gnupg
    - require:
      - cmd: apt_sources
  cmd: {# API #}
    - wait
    - name: "true"

{%- set pkgs = salt['pkg.list_pkgs']() %}
{%- for user, data in users.iteritems() %}
  {{ dict_default(data, "public_keys", {}) }}
  {{ dict_default(data, "private_keys", {}) }}
  {%- set private_keys = data["private_keys"] %}

  {%- for key_type in ("public", "private") %}

    {%- for keyid, key in data[key_type + "_keys"].iteritems() %}
gnupg_import_{{ key_type }}_key_{{ keyid }}_for_user_{{ user }}:
  module:
    - run
    - name: gpg.import_key
    - user: {{ user }}
    - text: |
        {{ key|indent(8) }}
    - require:
      - pkg: gnupg
    - require_in:
      - cmd: gnupg
    - unless: gpg --list{% if key_type == "private" %}-secret{% endif %}-keys --with-colons | grep {{ keyid }}
    {%- endfor %}
  {%- endfor %}

  {%- if 'gnupg' in pkgs and 'python-gnupg' in pkgs %}
    {%- set imported_keys = salt["gpg.list_keys"]() %}
    {%- for imported_key in imported_keys %}
      {#- The public is also imported when importing a secret key
      So, secret key must be deleted first before deleting the public key #}
      {%- if imported_key["keyid"] not in data["public_keys"] and imported_key["keyid"] not in private_keys %}
gnupg_delete_pub_key_{{ imported_key["keyid"] }}_for_user_{{ user }}:
  module:
    - run
    - name: gpg.delete_key
    - user: {{ user }}
    - keyid: {{ imported_key["keyid"] }}
    - require:
      - pkg: gnupg
      - cmd: gnupg_delete_all_priv_keys_for_user_{{ user }}
    - require_in:
      - cmd: gnupg
      {%- endif %}
    {%- endfor %}

    {%- set imported_private_keys = salt["gpg.list_secret_keys"]() %}
    {%- for imported_private_key in imported_private_keys %}
      {%- if imported_private_key["keyid"] not in private_keys %}
gnupg_delete_priv_key_{{ imported_private_key["keyid"] }}_for_user_{{ user }}:
  module:
    - run
    - name: gpg.delete_key
    - user: {{ user }}
    - keyid: {{ imported_private_key["keyid"] }}
    - delete_secret: True
    - require:
      - pkg: gnupg
    - require_in:
      - cmd: gnupg
    - watch_in:
      - cmd: gnupg_delete_all_priv_keys_for_user_{{ user }}
      {%- endif %}
    {%- endfor %}
  {%- endif %}

gnupg_delete_all_priv_keys_for_user_{{ user }}:
  cmd:
    - wait
    - name: echo "The keys from secret keyrings but not defined in the pillar has been deleted"
{%- endfor %}
