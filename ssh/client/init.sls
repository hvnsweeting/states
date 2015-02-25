{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt
  - ssh.common

openssh-client:
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
  pkg:
    - latest
    - require:
      - cmd: apt_sources

ssh_known_hosts:
  file:
    - managed
    - name: /etc/ssh/ssh_known_hosts
    - user: root
    - group: root
    - mode: 640
    - require:
      - pkg: openssh-client

{%- from 'ssh/common.sls' import root_home with context %}
{%- set root_home = root_home() -%}

{%- for domain, id in salt['pillar.get']('ssh:known_hosts', {}).items() %}
ssh_{{ domain }}:
  file:
    - append
    - name: /etc/ssh/ssh_known_hosts
    - makedirs: True
    - text: |
        {{ id }}
    - require:
      - file: {{ root_home }}/.ssh
      - file: ssh_known_hosts
    - require_in:
      - file: known_hosts
{%- endfor %}

known_hosts:
  file:
    - append
    - name: /etc/ssh/ssh_known_hosts
    - text: |
        github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
        bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw==
    - require:
      - file: ssh_known_hosts

/etc/ssh/keys:
  file:
    - directory
    - require:
      - pkg: openssh-client

{#- manage multiple ssh private keys for multiple users #}
{%- set managed_keys = [] -%}
{%- set managed_locals = [] %}{# track which local users exists to make sure it's not file.directory more than once #}
{%- for key in salt['pillar.get']('ssh:keys', []) -%}
  {%- set maps = key['map'] %}
  {%- for hostname in maps %}
    {%- set local_remotes = maps[hostname] if maps[hostname] != none else {'root': 'root'} %}
    {%- for local in local_remotes -%}
      {#- make sure /etc/ssh/keys/{{ local }} is managed only once -#}
      {%- if local not in managed_locals -%}
        {%- do managed_locals.append(local) %}
/etc/ssh/keys/{{ local }}:
  file:
    - directory
    - mode: 750
    - require:
      - file: /etc/ssh/keys
      {%- endif -%}
      {%- set remotes = local_remotes[local] %}
      {%- set remotes = [remotes] if remotes is string else remotes %}
      {%- for remote in remotes %}
        {%- set ssh_priv_key = '/etc/ssh/keys/{0}/{1}@{2}'.format(local, remote, hostname) -%}
        {%- do managed_keys.append(ssh_priv_key) %}
{{ ssh_priv_key }}:
  file:
    - managed
    - makedirs: True {#- file.directory state run after this will set the expected dir mode/owner #}
    - mode: 400
    - contents: |
        {{ key['contents'] | indent(8) }}
    - require:
      - file: /etc/ssh/keys
    - require_in:
      - file: /etc/ssh/keys/{{ local }}
      {%- endfor %}
    {%- endfor -%}
  {%- endfor -%}
{%- endfor -%}

{#- remove all unmanaged keys -#}
{%- for keyfile in salt['file.find']('/etc/ssh/keys', type='f') -%}
  {%- if keyfile not in managed_keys %}
{{ keyfile }}:
  file:
    - absent
  {%- endif -%}
{%- endfor %}

{%- set root_key = salt['pillar.get']('ssh:root_key', False) -%}
{%- set extensions = ('', '.pub') -%}
{%- if root_key -%}
    {%- set type = 'rsa' if 'BEGIN RSA PRIVATE' in root_key else 'dsa' %}
root_ssh_private_key:
  file:
    - managed
    - name: {{ root_home }}/.ssh/id_{{ type }}
    - contents: |
        {{ root_key | indent(8) }}
    - user: root
    - group: root
    - mode: 400
    - require:
      - file: {{ root_home }}/.ssh
    - require_in:
      - pkg: openssh-client
  cmd:
    - wait
    - name: ssh-keygen -y -f {{ root_home }}/.ssh/id_{{ type }} > {{ root_home }}/.ssh/id_{{ type }}.pub
    - watch:
      - file: root_ssh_private_key
    - require:
      - pkg: openssh-client

    {#- remove the other private and public key #}
    {%- for extension in extensions %}
{{ root_home }}/.ssh/id_{{ 'dsa' if type == 'rsa' else 'rsa' }}{{ extension }}:
  file:
    - absent
    - require_in:
      - file: root_ssh_private_key
    {%- endfor -%}

{%- else -%}
    {#-  remove all public and private key of root user -#}
    {%- for type in ('rsa', 'dsa') -%}
        {%- for extension in extensions %}
{{ root_home }}/.ssh/id_{{ type }}{{ extension }}:
  file:
    - absent
    - require_in:
      - pkg: openssh-client
        {%- endfor -%}
    {%- endfor -%}
{%- endif -%}
