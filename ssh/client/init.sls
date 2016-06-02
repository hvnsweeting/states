{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - ssh.common

openssh-client:
  pkg:
    - latest
    - require:
      - cmd: apt_sources
{#- API #}
  file:
    - managed
    - name: /etc/ssh/ssh_known_hosts
    - user: root
    - group: root
    - mode: 444
    - replace: False

ssh_systemwide_config:
  file:
    - managed
    - name: /etc/ssh/ssh_config
    - template: jinja
    - user: root
    - group: root
    - mode: 444
    - source: salt://ssh/client/config.jinja2
    - require:
      - pkg: openssh-client
    - require_in:
      - file: openssh-client

/etc/ssh/keys:
  file:
    - directory
    - require:
      - pkg: openssh-client

{#- manage multiple ssh private keys for multiple users #}

{%- for domain in salt['pillar.get']('ssh:hosts', {}) %}
ssh_known_host_{{ domain }}:
  ssh_known_hosts:
    - present
    {# we need to set port, it does not work with hash_known_hosts #}
    - hash_known_hosts: False
    - name: {{ domain }}
  {%- set port = salt['pillar.get']('ssh:hosts:' ~ domain ~ ':port', 22) %}
  {%- if port %}
    - port: {{ port }}
  {%- endif %}
  {%- set fingerprint = salt['pillar.get']('ssh:hosts:' ~ domain ~ ':fingerprint', None) %}
  {%- if fingerprint %}
    - fingerprint: {{ fingerprint }}
  {%- endif %}
    - config: /etc/ssh/ssh_known_hosts
    - require_in:
    {#- under-hood ssh_known_hosts and pkg installing will in charge of make
        sure system wide ssh_known_hosts file exist, this is require_in
        file: openssh-client to use it as API #}
      - file: openssh-client
    - require:
      - pkg: openssh-client
{%- endfor %}

{%- set user_keys = salt['pillar.get']('ssh:users', {}) -%}
{%- set keyname_contents = salt['pillar.get']('ssh:keys', {}) -%}

{%- for local_user in user_keys %}
ssh_{{ local_user }}:
  group:
    - present
    - name: {{ local_user }}
  user:
    - present
    - name: {{ local_user }}
    - gid_from_name: True
    - require:
      - group: ssh_{{ local_user }}

ssh_key_dir_for_user_{{ local_user }}:
  file:
    - directory
    - clean: True
    - name: /etc/ssh/keys/{{ local_user }}
    - user: {{ local_user }}
    - group: {{ local_user }}
    - mode: 750
    - require:
      - file: /etc/ssh/keys
      - user: ssh_{{ local_user }}
      - group: ssh_{{ local_user }}
    - require_in:
      - file: openssh-client

  {%- for keyname in user_keys[local_user] %}
ssh_private_key_{{ local_user }}_{{ keyname }}:
  file:
    - managed
    - name: /etc/ssh/keys/{{ local_user }}/{{ keyname }}
    - makedirs: True {#- file.directory state run after this will set the expected dir mode/owner #}
    - user: {{ local_user }}
    - group: {{ local_user }}
    - mode: 400
    - contents: |
        {{ keyname_contents[keyname] | indent(8) }}
    - require:
      - file: /etc/ssh/keys
      - user: ssh_{{ local_user }}
      - group: ssh_{{ local_user }}
    - require_in:
      - file: ssh_key_dir_for_user_{{ local_user }}

ssh_public_key_{{ local_user }}_{{ keyname }}:
  cmd:
    - wait
    - name: ssh-keygen -y -f /etc/ssh/keys/{{ local_user }}/{{ keyname }} > /etc/ssh/keys/{{ local_user }}/{{ keyname }}.pub
    - watch:
      - file: ssh_private_key_{{ local_user }}_{{ keyname }}
    - require:
      - pkg: openssh-client
  file:
    - managed
    - name: /etc/ssh/keys/{{ local_user }}/{{ keyname }}.pub
    - user: {{ local_user }}
    - group: {{ local_user }}
    - mode: 400
    - replace: False
    - require:
      - cmd: ssh_public_key_{{ local_user }}_{{ keyname }}
    - require_in:
      - file: ssh_key_dir_for_user_{{ local_user }}

ssh_config_{{ local_user }}_{{ keyname }}_accumulate:
  file:
    - accumulated
    - name: ssh_identity_config
    - filename: /etc/ssh/ssh_config
    - require_in:
      - file: ssh_systemwide_config
    - text: {{ keyname }}
  {%- endfor -%}
{%- endfor -%}

{#- forgot_hosts formed as a dict to be consistent with its counter part - hosts #}
{%- for domain in salt['pillar.get']('ssh:forgot_hosts', {}) %}
ssh_forgot_host_{{ domain }}:
  ssh_known_hosts:
    - absent
    - name: {{ domain }}
    - require_in:
      - file: openssh-client
    - require:
      - pkg: openssh-client
{%- endfor %}
