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

android_sdk_buildtools_and_api:
  cmd:
    - run
    - env:
      - ANDROID_HOME: /usr/local/android-sdk-linux
    - name: echo y | $ANDROID_HOME/tools/android update sdk --no-ui --all --filter {% for buildtools_ver in salt['pillar.get']('android:buildtools_versions') -%}
      build-tools-{{ buildtools_ver }},
      {%- endfor -%}
      {%- for api_ver in salt['pillar.get']('android:sdk_api_versions') -%}
      android-{{ api_ver }},
      {%- endfor %}
    - require:
      - file: android_sdk
    - unless: {% for buildtools_ver in salt['pillar.get']('android:buildtools_versions') -%}
      test -d /usr/local/android-sdk-linux/build-tools/{{ buildtools_ver }} &&
              {%- endfor -%}
              {%- for api_ver in salt['pillar.get']('android:sdk_api_versions') -%}
      test -d /usr/local/android-sdk-linux/platforms/android-{{ api_ver }}
                {%- if not loop.last %}&&{%- endif -%}
              {%- endfor %}
