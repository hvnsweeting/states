{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - gradle
  - java.7.jdk
  - local
  - salt.minion.deps

android_sdk:
  pkg:
    - installed
    - pkgs:
      - libncurses5:i386
      - libstdc++6:i386
      - zlib1g:i386
    - require:
      - cmd: apt_sources
  archive:
    - extracted
    - name: /usr/local/
{%- set files_archive = salt['pillar.get']('files_archive', False) %}
{%- if files_archive %}
    - source: {{ files_archive }}/mirror/android-sdk_r24.3.2-linux.tgz
{%- else %}
    - source: http://dl.google.com/android/android-sdk_r24.3.2-linux.tgz
{%- endif %}
    - source_hash: sha1=4a10e62c5d88fd6c2a69db12348cbe168228b98f
    - archive_format: tar
    - tar_options: z
    - if_missing: /usr/local/android-sdk-linux/tools/android
    - require:
      - file: /usr/local
      - pkg: salt_minion_deps
  file:
    - append
    - name: /etc/environment
    - text: |
        export ANDROID_HOME="/usr/local/android-sdk-linux"
    - require:
      - archive: android_sdk
      - pkg: android_sdk

{%- for sdk in salt['pillar.get']('android:sdks') %}
android_sdk_{{ sdk }}:
  cmd:
    - run
    - env:
      - ANDROID_HOME: /usr/local/android-sdk-linux
    - name: echo y | $ANDROID_HOME/tools/android update sdk --no-ui --all --filter {{ sdk }}
    - unless: {% if sdk.startswith('build-tools') -%}
        test -d /usr/local/android-sdk-linux/build-tools/{{ sdk | replace('build-tools-', '') }}
              {%- elif sdk.startswith('android') -%}
        test -d /usr/local/android-sdk-linux/platforms/android-{{ sdk | replace('android-', '') }}
              {%- elif sdk.startswith('extra') -%}
        test -d /usr/local/android-sdk-linux/extras/{{ sdk.split('-')[1] }}/{{ sdk.split('-')[2] }}
              {%- endif %}
    - require:
      - file: android_sdk
{%- endfor %}
