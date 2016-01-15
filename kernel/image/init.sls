{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt

kernel:
  pkg:
    - installed
    - name: linux-image-{{ grains['kernelrelease'] }}
    - required:
      - cmd: apt_sources

{%- set files_archive = salt['pillar.get']('files_archive', False) %}

bikeshed:
  pkgrepo:
    - managed
{%- if files_archive %}
    - name: deb {{ files_archive|replace('https://', 'http://') }}/mirror/bikeshed {{ grains['oscodename'] }} main
    - key_url: salt://kernel/image/key.gpg
{%- else %}
    - ppa: bikeshed/ppa
{%- endif %}
    - file: /etc/apt/sources.list.d/bikeshed.list
    - clean_file: True
    - require:
      - cmd: apt_sources
  pkg:
    - installed
    - require:
      - pkgrepo: bikeshed
  cmd:
    - run
    - name: purge-old-kernels -q -y --force-yes
    - require:
      - pkg: bikeshed
