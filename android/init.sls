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
    - if_missing: /usr/local/android-sdk-linux
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

android_sdk_buildtools:
  cmd:
    - run
    - env:
      - ANDROID_HOME: /usr/local/android-sdk-linux
    - name: echo y | $ANDROID_HOME/tools/android update sdk -u -a -t {{ salt['pillar.get]('android:buildtools_index') }}
    - require:
      - file: android_sdk


android_sdk_platform_api:
  cmd:
    - run
    - env:
      - ANDROID_HOME: /usr/local/android-sdk-linux
    - name: echo y | $ANDROID_HOME/tools/android update sdk -u -a -t {{ salt['pillar.get]('android:sdk_api_version') }}
    - require:
      - file: android_sdk
