{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

ssl-cert:
  pkg:
    - purged
  group:
    - absent
    - require:
      - pkg: ssl-cert
  {#- don't remove /etc/ssl directory
  /etc/ssl/openssl.cnf is mandatory to use openssl #}
  file:
    - absent
    - names:
      - /etc/ssl/certs
      - /etc/ssl/private
      - /etc/ssl/dhparam.pem
    - require:
      - pkg: ssl-cert
{#- regenerate SSL certs or the machine after running absent will not able
    to use SSL (esp: HTTPS) #}
  cmd:
    - run
    {#- update-ca-certificates will fail if the directory does not exist #}
    - name: mkdir /etc/ssl/certs; update-ca-certificates
    - require:
      - file: ssl-cert
