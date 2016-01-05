{#- Usage of this is governed by a license that can be found in doc/license.rst

These are required to run some Salt states/modules
for e.g, `salt.modules.dig` need `dnsutils` to be installed
-#}

salt_minion_deps:
  pkg:
    - installed
    - pkgs:
      - patch {# for file.patch #}
      - lsb-release
      - openssh-client {#- for ssh_known_host #}
      - zip {#- for archive.zip module #}
      - unzip
      - dnsutils
      - python-psutil
      - python-openssl {#- for tls module #}
      - python-ipy {#- for common.calc_range #}
      - gnupg
      - python-boto
      - python-gnupg
{%- if grains['virtual'] != 'openvzve' %}
      - pciutils
      - dmidecode
{%- endif %}
