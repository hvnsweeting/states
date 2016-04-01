{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

quagga:
  {#- WARNING: The Quagga routing daemon has to be stopped to proceed.
  This could lead to BGP flaps or loss of network connectivity.
  Do you really want to stop the Quagga daemon? #}
  debconf:
    - set
    - data:
        'quagga/really_stop': {'type': 'boolean', 'value': True}
  service:
    - dead
    - require:
      - debconf: quagga
  module:
    - run
    - name: pkg.unhold
    - m_name: quagga
  pkg:
    - purged
    - require:
      - service: quagga
      - module: quagga
  group:
    - absent
    - name: quaggavty
    - require:
      - pkg: quagga
  user:
    - absent
    - name: quaggavty
    - require:
      - group: quagga
