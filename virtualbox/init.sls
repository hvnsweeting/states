{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- set major_version = '5.0' %}
{%- set full_version = major_version ~ '.14' %}
{%- from "os.jinja2" import os with context %}
include:
  - apt
  - kernel.image.dev

virtualbox:
  pkgrepo:
    - managed
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/virtualbox/{{ full_version }} {{ grains['oscodename'] }} contrib
{%- else %}
    - name: deb http://download.virtualbox.org/virtualbox/debian {{ grains['oscodename'] }} contrib
{%- endif %}
    - file: /etc/apt/sources.list.d/virtualbox.list
    - key_url: salt://virtualbox/key.gpg
    - clean_file: True
    - require:
      - cmd: apt_sources
  pkg:
    - installed
    - name: virtualbox-{{ major_version }}
    - hold: True
    - require:
      - pkgrepo: virtualbox
      - pkg: kernel-headers
{#- use RDP for VDRP, required for Windows machine #}
  cmd:
    - wait
    - name: vboxmanage setproperty vrdeextpack 'Oracle VM VirtualBox Extension Pack'
    - watch:
      - cmd: virtualbox-oracle-extpack
  service:
    - running
    - enable: True
    - watch:
      - pkg: virtualbox
      - pkg: kernel-headers

{#- Oracle VM VirtualBox Extension Pack #}
{%- if os.is_precise %}
  {%- set extpack_file = "Oracle_VM_VirtualBox_Extension_Pack-4.1.12-77245.vbox-extpack" %}
  {%- set extpack_hash = "sha256=57a98286a9393e49c36ab8873878a89d0ac6b1179bf9a5c0d5fd517e272a8881" %}
{%- elif os.is_trusty %}
  {%- set extpack_file = "Oracle_VM_VirtualBox_Extension_Pack-" ~ full_version ~ "-105127.vbox-extpack" %}
  {%- set extpack_hash = "md5=a1c1794967ddf9342ca1780e4121e1f2" %}
{%- endif %}
{%- if files_archive %}
  {%- set source = files_archive ~ "/mirror/virtualbox/" ~ full_version ~ "/" ~ extpack_file %}
{%- else %}
  {%- set source = "http://download.virtualbox.org/virtualbox/" ~ full_version ~ "/" ~ extpack_file %}
{%- endif %}

virtualbox-oracle-extpack:
  file:
    - managed
    - name: {{ opts['cachedir'] }}/{{ extpack_file }}
    - source: {{ source }}
    - source_hash: {{ extpack_hash }}
    - user: root
    - group: root
    - mode: 644
  cmd:
    - wait
    - name: vboxmanage extpack install --replace {{ opts['cachedir'] }}/{{ extpack_file }}
    - watch:
      - pkg: virtualbox
      - file: virtualbox-oracle-extpack

cleanup_virtualbox-oracle-extpack:
  file:
    - absent
    - name: {{ opts['cachedir'] }}/{{ extpack_file }}
    - require:
      - cmd: virtualbox-oracle-extpack

/etc/init.d/virtualbox:
 file:
   - managed
   - template: jinja
   - user: root
   - group: root
   - mode: 755
   - source: salt://virtualbox/sysvinit.jinja2
   - require:
     - pkg: virtualbox
   - require_in:
     - service: virtualbox
