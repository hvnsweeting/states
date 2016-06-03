{#- Usage of this is governed by a license that can be found in doc/license.rst
-*- ci-automatic-discovery: off -*-

This state take a salt-minion and remove all debian packages that aren't
required to run only it.
Useful to identify if dependencies are missing.
-#}

include:
  - deborphan
  - ttys

clean_pkg:
  pkg:
    - purged
    - env:
        'SUDO_FORCE_REMOVE': 'yes'
    - pkgs:
      - accountsservice
      - acpid
      - anacron
      - apparmor
      - apparmor-utils
      - apport
      - apport-symptoms
      - apt-transport-https
      - apt-utils
      - apt-xapian-index
      - aptitude
      - at
      - bash-completion
      - bc
      - bind9-host
      - busybox-static
      - byobu
{# Required for python-requests which in turn depended by salt-common
    from 2014.7
      - ca-certificates
#}
      - cloud-init
      - cloud-initramfs-growroot
      - cloud-initramfs-rescuevol
      - cloud-utils
      - command-not-found
      - command-not-found-data
      - console-data
      - console-setup
      - cpp
      - cpp-4.6
      - cron
      - curl
      - dbus
      - dmidecode
      - dnsutils
      - dosfstools
      - dpkg-dev
      - ed
      - eject
      - euca2ools
      - fonts-ubuntu-font-family-console
      - friendly-recovery
      - ftp
      - fuse
      - fuse-utils
      - g++
      - gcc
      - geoip-database
      - gir1.2-glib-2.0
      - groff-base
      - hdparm
      - info
      - install-info
      - installation-report
      - iptables
      - iputils-ping
      - iputils-tracepath
      - irqbalance
      - iso-codes
      - iw
      - kbd
      - keyboard-configuration
      - krb5-locales
      - landscape-client
      - landscape-common
      - language-selector-common
      - laptop-detect
      - less
{#- required by python-apt - dependency of salt-common
      - libapt-inst1.4
#}
      - libclass-accessor-perl
      - libclass-isa-perl
      - libcurl3
{# required by python-pycurl, salt-common 2016.3.0 dependency
      - libcurl3-gnutls
#}
      - libdpkg-perl
      - liberror-perl
      - libio-string-perl
      - libjs-jquery
      - liblockfile-bin
      - libparse-debianchangelog-perl
      - libsub-name-perl
      - libswitch-perl
      - libtimedate-perl
      - libx11-data
      - locales
      - lockfile-progs
      - logrotate
      - lsb-release
      - lshw
      - lsof
      - ltrace
      - make
      - man-db
      - manpages
      - memtest86+
      - mlocate
      - mtr-tiny
      - nano
      - netcat-openbsd
      - ntfs-3g
      - ntpdate
      - openssh-server
      - os-prober
      - parted
      - patch
      - perl
      - perl-modules
      - popularity-contest
      - powermgmt-base
      - ppp
      - pppconfig
      - pppoeconf
      - psmisc
      - python-apport
{#- required by salt-common 2014.7
      - python-apt
      - python-apt-common
      - python-chardet
#}
      - python-boto
      - python-cheetah
      - python-configobj
      - python-dbus
      - python-dbus-dev
      - python-debian
      - python-gdbm
      - python-gi
      - python-gnupginterface
      - python-httplib2
      - python-keyring
      - python-launchpadlib
      - python-lazr.restfulclient
      - python-lazr.uri
      - python-newt
      - python-oauth
      - python-openssl
      - python-pam
      - python-paramiko
      - python-problem-report
{# Required by  python-tornado, salt-common 2016.3.0 dependency
      - python-pycurl
#}
      - python-serial
      - python-simplejson
      - python-software-properties
      - python-twisted-bin
      - python-twisted-core
      - python-twisted-names
      - python-twisted-web
      - python-wadllib
      - python-xapian
      - python-zope.interface
      - resolvconf
      - rsync
      - rsyslog
      - screen
      - sgml-base
      - ssh-import-id
      - strace
      - sudo
      - tasksel
      - tasksel-data
      - tcpd
      - tcpdump
      - telnet
      - time
      - tmux
      - ubuntu-minimal
      - ubuntu-standard
      - ufw
      - unattended-upgrades
      - update-manager-core
      - update-notifier-common
      - ureadahead
      - usbutils
      - uuid-runtime
      - vim
      - vim-runtime
      - w3m
      - wget
      - whiptail
      - whoopsie
      - wireless-tools
      - wpasupplicant
      - xauth
      - xz-lzma
      - xkb-data
      - xml-core

{% for service in ('acpid', 'console-setup', 'dbus', 'whoopsie') %}
/var/log/upstart/{{ service }}.log:
  file:
    - absent
    - require:
      - pkg: clean_pkg
{% endfor %}

{%- for pkg in ('cloud-init', 'ufw') %}
/var/log/{{ pkg }}.log:
  file:
    - absent
    - require:
      - pkg: clean_pkg
{%- endfor -%}

{%- for file in ('/tmp/bootstrap-salt.log', '/var/lib/cloud', '/var/cache/apt-xapian-index') %}
{{ file }}:
  file:
    - absent
    - require:
      - pkg: clean_pkg
{%- endfor -%}

{%- if salt['cmd.has_exec']('deborphan') -%}
    {%- for pkg in salt['cmd.run']('deborphan').split("\n") if ':' not in pkg -%}
        {%- if pkg != '' -%}
            {%- if loop.first %}
orphans:
  pkg:
    - purged
    - require:
      - pkg: clean_pkg
    - pkgs:
            {%- endif %}
      -  {{ pkg }}
        {%- endif -%}
    {%- endfor -%}
{%- endif -%}
