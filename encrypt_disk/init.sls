{#- Usage of this is governed by a license that can be found in doc/license.rst
     -*- ci-automatic-discovery: off -*-

     Test will be done in encrypt_disk.test
-#}
include:
  - apt

cryptsetup:
  pkg:
    - latest
    - require:
      - cmd: apt_sources

{%- set enc = salt["pillar.get"]("encrypt_disk", {}) %}
{%- for disk, config in enc.iteritems() %}
  {%- set device_name = disk|replace("/", "_") %}
  {%- set fstype = salt["pillar.get"]("encrypt_disk:" ~ disk ~ ":fstype", "ext4") %}
  {%- set mount_point = salt["pillar.get"]("encrypt_disk:" ~ disk ~ ":block", False) %}
  {%- set bind_dirs = salt["pillar.get"]("encrypt_disk:" ~ disk ~ ":bind", []) %}
  {%- set passphrase = salt["pillar.get"]("encrypt_disk:" ~ disk ~ ":passphrase", False)|default(False, boolean=True) %}
  {%- if passphrase %}
luksFormat_disk_{{ disk }}:
  cmd:
    - run
    - name: echo -n '{{ passphrase }}' | cryptsetup luksFormat '{{ disk }}'
    - unless: cryptsetup luksUUID '{{ disk }}'
    - require:
      - pkg: cryptsetup

luksOpen_disk_{{ disk }}:
  cmd:
    - run
    - name: echo -n '{{ passphrase }}' | cryptsetup luksOpen '{{ disk }}' '{{ device_name }}'
    - unless: test -b /dev/mapper/'{{ device_name }}'
    - require:
      - cmd: luksFormat_disk_{{ disk }}

mkfs_disk_{{ disk }}:
  cmd:
    - run
    - name: mkfs -t '{{ fstype }}' /dev/mapper/'{{ device_name }}'
    - require:
      - cmd: luksOpen_disk_{{ disk }}
    - onchanges:
      - cmd: luksFormat_disk_{{ disk }}
    - watch_in:
      - cmd: disk_encryption

  {%- endif %}

  {%- if mount_point %}
mount_disk_{{ disk }}:
  mount:
    - mounted
    - name: {{ mount_point }}
    - device: /dev/mapper/{{ device_name }}
    - fstype: {{ fstype }}
    - mkmnt: True
    - persist: True
    - opts:
      - nobootwait
    - require:
      - cmd: mkfs_disk_{{ disk }}
    - watch_in:
      - cmd: disk_encryption

      {%- for dir in bind_dirs %}
        {%- set src = mount_point ~ dir %}
encrypt_disk_bind_{{ dir }}:
{#- only create directory if not already existed #}
  file:
    - directory
    - name: {{ src }}
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
    - unless: test -d {{ src }}
    - require:
      - mount: mount_disk_{{ disk }}
  mount:
    - mounted
    - name: {{ dir }}
    - device: {{ src }}
    - fstype: {{ fstype }}
    - mkmnt: True
    - persist: True
    - opts:
      - bind
      - nobootwait
    - require:
      - file: encrypt_disk_bind_{{ dir }}
    - watch_in:
      - cmd: disk_encryption
      {%- endfor %}
  {%- endif %}
{%- endfor %}

disk_encryption:
  cmd:
    - wait
    - name: /bin/echo "Disks encryption completed!"
