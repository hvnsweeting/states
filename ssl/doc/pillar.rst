Pillar
======

.. include:: /doc/include/add_pillar.inc

- :doc:`/apt/doc/index` :doc:`/apt/doc/pillar`

Optional
--------

Format::

  ssl:
    expiry_days: 15
    letsencrypt_admin_email: admin@example.com
    certs:
      [key_name]:
        server_key: ssl key content
        server_crt: ssl cert content
        ca_crt: ssl ca cert content
      [other_key_name]:
        server_key: other ssl key content
        server_crt: other ssl cert content
        ca_crt: other ssl ca cert content
      [domain_name]:
        letsencrypt: True

Example::

  ssl:
    dhparam:
      key_size: 2048
    certs:
      example_com:
        server_crt: |
          -----BEGIN CERTIFICATE-----
          MIIDjjCCAnYCCQD2WzRbbzkiZDANBgkqhkiG9w0BAQUFADCBiDELMAkGA1UEBhMC
          Vk4xDjAMBgNVBAgMBUhhbm9pMQ4wDAYDVQQHDAVIYW5vaTEQMA4GA1UECgwHRkFN
          SUxVRzELMAkGA1UECwwCSVQxFDASBgNVBAMMC2h2bnN3ZWV0aW5nMSQwIgYJKoZI
          hvcNAQkBFhVodm5zd2VldGluZ0BnbWFpbC5jb20wHhcNMTMwNjAzMTQ1NDEyWhcN
          MTQwNjAzMTQ1NDEyWjCBiDELMAkGA1UEBhMCVk4xDjAMBgNVBAgMBUhhbm9pMQ4w
          DAYDVQQHDAVIYW5vaTEQMA4GA1UECgwHRkFNSUxVRzELMAkGA1UECwwCSVQxFDAS
          BgNVBAMMC2h2bnN3ZWV0aW5nMSQwIgYJKoZIhvcNAQkBFhVodm5zd2VldGluZ0Bn
          bWFpbC5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCmR76C/oDs
          UAnC9IfdTJNoPwCI08fatAIW+rUnaaNXkOjBWu3VeKWmTgW1OEiWjKYMQeif1zFY
          WDsqffwhR9OtvrPNaormHC3h4rvm0PnBR52J7EcIJugaLTts5Q1tRCQ67JkWDxal
          CrJWHR6ZS8Cx2sP52lr7769KyW3Cbv9RmzE6vDxx1znlzwIg9ettVPHCAtom/EBE
          6MP8AWnj4gmJVlZQ+bg/th7EBPfFJqhN66QDYIUrrkv6xcAz996ByNdUUSddAjT/
          pZRTdhU1/l2hchWypWCJe0a6NgDIFz4TZitvIuEQdiZ+s1B7wnghrFZIC+lohRcx
          7Rx5DgafakRhAgMBAAEwDQYJKoZIhvcNAQEFBQADggEBABKoZq4fUfl/h31Gq3SI
          jZSsR8BpM9cEMalyvL3MYJ30JlAam4EAofxDR3yslIsHhbwG0F5uv/e5kwBX0TLI
          B4vlg97d0bKknL8DTT5XVTWuiViuJRap3JkTJbH8vBl62CZKT0Z4GN9Sfh8mKwFv
          299gpX/CYa0Le+2ddGBD9Ego2Ull8cdsIonETNdsb4NFdUuF1ZG1ExKpFePWSTc5
          WLopBZelsDRtRw26biiiktfKO4XFeScrOCLXGUdQ4k/0YbR1YATP17lnUr/Sr0wb
          Mw4eFh1fhb5VhOKymIA1mrYDRrgRhKqqQ7DzyM/l1/RvKzkYldBMextp7hfD0RQt
          /6A=
          -----END CERTIFICATE-----
        ca_crt: |
          -----BEGIN CERTIFICATE-----
          MIIDojCCAoqgAwIBAgIQE4Y1TR0/BvLB+WUF1ZAcYjANBgkqhkiG9w0BAQUFADBr
          MQswCQYDVQQGEwJVUzENMAsGA1UEChMEVklTQTEvMC0GA1UECxMmVmlzYSBJbnRl
          cm5hdGlvbmFsIFNlcnZpY2UgQXNzb2NpYXRpb24xHDAaBgNVBAMTE1Zpc2EgZUNv
          bW1lcmNlIFJvb3QwHhcNMDIwNjI2MDIxODM2WhcNMjIwNjI0MDAxNjEyWjBrMQsw
          CQYDVQQGEwJVUzENMAsGA1UEChMEVklTQTEvMC0GA1UECxMmVmlzYSBJbnRlcm5h
          dGlvbmFsIFNlcnZpY2UgQXNzb2NpYXRpb24xHDAaBgNVBAMTE1Zpc2EgZUNvbW1l
          cmNlIFJvb3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCvV95WHm6h
          2mCxlCfLF9sHP4CFT8icttD0b0/Pmdjh28JIXDqsOTPHH2qLJj0rNfVIsZHBAk4E
          lpF7sDPwsRROEW+1QK8bRaVK7362rPKgH1g/EkZgPI2h4H3PVz4zHvtH8aoVlwdV
          ZqW1LS7YgFmypw23RuwhY/81q6UCzyr0TP579ZRdhE2o8mCP2w4lPJ9zcc+U30rq
          299yOIzzlr3xF7zSujtFWsan9sYXiwGd/BmoKoMWuDpI/k4+oKsGGelT84ATB+0t
          vz8KPFUgOSwsAGl0lUq8ILKpeeUYiZGo3BxN77t+Nwtd/jmliFKMAGzsGHxBvfaL
          dXe6YJ2E5/4tAgMBAAGjQjBAMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQD
          AgEGMB0GA1UdDgQWBBQVOIMPPyw/cDMezUb+B4wg4NfDtzANBgkqhkiG9w0BAQUF
          AAOCAQEAX/FBfXxcCLkr4NWSR/pnXKUTwwMhmytMiUbPWU3J/qVAtmPN3XEolWcR
          zCSs00Rsca4BIGsDoo8Ytyk6feUWYFN4PMCvFYP3j1IzJL1kk5fui/fbGKhtcbP3
          LBfQdCVp9/5rPJS+TUtBjE7ic9DjkCJzQ83z7+pzzkWKsKZJ/0x9nXGIxHYdkFsd
          7v3M9+79YKWxehZx0RbQfBI8bGmX265fOZpwLwU8GUYEmSA20GBuYQa7FkKMcPcw
          ++DbZqMAAb3mLNqRX6BGi01qnD093QVG/na/oAo85ADmJ7f/hC3euiInlhBx6yLt
          398znM/jra6O1I7mT1GvFpLgXPYHDw==
          -----END CERTIFICATE-----
        server_key: |
          -----BEGIN RSA PRIVATE KEY-----
          MIIEowIBAAKCAQEApke+gv6A7FAJwvSH3UyTaD8AiNPH2rQCFvq1J2mjV5DowVrt
          1Xilpk4FtThIloymDEHon9cxWFg7Kn38IUfTrb6zzWqK5hwt4eK75tD5wUediexH
          CCboGi07bOUNbUQkOuyZFg8WpQqyVh0emUvASdRD+dpa+++vSsltwm7/UZsxOrw8
          cdc55c8CIPXrbVTxwgLaJvxAROjD/AFp4+IJiVZWUPm4P7YexAT3xSaoTeukA2CF
          K65L+sXAM/fegcjXVFEnXQI0/6WUU3YVNf5doXIVsqVgiXtGujYAyBc+E2YrbyLh
          EHYmfrNQe8J4IaxWSAvpaIUXMe0ceQ4Gn2pEYQIDAQABAoIBAHFDU2jlNSpCxrNu
          X5GFVK9gotuQ7oRxsy617WmAUowWIAV9C54qRSOH5+luAjvSaFTXHD6slWcpCnxC
          PtjolS63RMB6f0yJC1PfXsC1vjpCrvPA5w2NevJBt0XQrBmuncMpYImfE3yuUZXI
          1gvzhrlfW7i4XNtZg5y8ojAb7XxG0eN4sC5jfMGDs2k+FTq0dhPT/ax4h0JU8MEz
          +xmtA0DM0kAJmEW9XSMYOceRC7Fu5sD9VeUYGwaErpPYwtCbVIKzlZoiiWl3n+oM
          rDmqxvYSZBQks9xI1p91n+h+8HLRHLJCHyLSzoLSjMn59UIhaD8ewZnKpcTRWegK
          1F+PjYUCgYEA0PEgkYKgUEFjT4eWMCCytrDhR2YM/OYjtRssmWQv0hiw2LNdzvJy
          PU2d1V/hScif6FAipoYGaZPYtNMDIfs7POD2RiHofyd2TKaImU8MsYxgzZ9ewt05
          r0Ahy9m+PL/ezdTHyJP3i6eCWr/CuRu9HbTljKIrZjsbggeU+MqvK+cCgYEAy7rk
          fm7l6+nF1cr8uePM8Y2Mqi1P+UGrynIr55gbnSgItguZrEzwvCIUIz1hv5r5n6Kt
          9anZCoA0tyU0cciwnNSOe+yh8HPUC6FFglWd5xkr5p+e88dO6HcomNbXnt6i7GHB
          iXb48KIGarZVqrvIIaxh2uqgUlQWE5LiZxagxHcCgYAJyNDqn4BcYcOBzOqmlFFq
          JrxV+JxxF2HisEQVZtCqeQeHDlc9QrNA1aqnfFbzepaqbV5CCBKyzP6f8SW7aKVs
          g2hk/l+B3No4WrAY5c/FXLqHxofMfkmeQFWU0zyKYb3QS7+TUAKOoqiDEWnP+1GO
          25LIVCvOHMR8AVjjkbJETwKBgQC4gAWj9pykXG58ojrjwch9TRqBl02gxvdj/KeE
          Mj13wqS48KJ35qnxRs+D5nfahOfhyPrPysSy/M5AuiHXlc9UCC8NTYyObOcwrRl8
          4jqA6kvWrOHPlcUBQ8BxQce9qZRUjGcwLZ1elu1GwN+uIicpT6rDDc6pIFtp2JDO
          mTB5GwKBgDe77vGi1ZP3mgdaJMNU1FisoNG7HZifcswGXXqiedViIrsENqImajic
          FlcWP0vUXFd/7cTKaJnuMBqk5EUs+amQ6PueGdhdoffNahaAquzRitHElpXz4GVC
          N+AdoEPIjHeWgrEwlgZDW3DjUeJbUl5uG2UHmff9q76Ti2mfsBHS
          -----END RSA PRIVATE KEY-----

      example_org:
        ...

Requires files in source:

- ``ca.crt`` Bundled certificate
- ``server.crt`` Server certificate
- ``server.key`` Server private key
- ``server.csr`` Server Certificate Signing Request.
  A CSR or Certificate Signing request is a block of encrypted text that is
  generated on the server that the certificate will be used on. It contains
  information that will be included in your certificate such as your
  organization name, common name (domain name), locality, and country. It also
  contains the public key that will be included in your certificate. A private
  key is usually created at the same time that you create the CSR.

How to generate a CSR (requires an existing key file)::

  openssl req -new -keyout server.key -out server.csr

How to generate a new CSR (no need for existing key file)::

  openssl req -new -newkey rsa:2048 -nodes -keyout server.key -out server.csr

How to decode a CSR::

  openssl req -in server.csr -noout -text

To use those SSL files in your states, you need to do the following:

- Add a pillar key for your state that hold the name of the SSL key name
  defined in salt['pillar.get']('ssl'), such as example_com in previous example.

  It can be: ``my_app:ssl``: ``example_com``
- If the daemon isn't running as root, add the group ``ssl-cert`` to the user
  with which that daemon run.
- Add ``ssl`` to the list of included sls file
- Requires the following three condition before starting your service:
    ``- cmd: ssl_cert_and_key_for_{{ salt['pillar.get']('my_app:ssl') }}``

- In the config file you point to the same path to reach those files, like::

    /etc/ssl/certs/{{ pillar['my_app']['ssl'] }}_chained.crt;
    tls_key = /etc/ssl/private/{{ pillar['my_app']['ssl'] }}.pem;

.. _pillar-ssl-dhparam-key_size:

ssl:dhparam:key_size
~~~~~~~~~~~~~~~~~~~~

Number of bits of `DH
<http://en.wikipedia.org/wiki/Diffie–Hellman_key_exchange>`_ parameters.

Default: ``2048`` bits.

.. _pillar-ssl-certs:

ssl:certs
~~~~~~~~~

Define one or multiple SSL certificates.

Default: ``{}``.

ssl:letsencrypt_admin_email
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Email address of admin who will be contacted if Letsencrypt certificates are
about to expiry.

Default: not use letsencrypt (``None``).

Conditional
-----------

.. _pillar-ssl-certs-name-selfsigned:

ssl:certs:{{ name }}:selfsigned
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Whether cert is selfsigned.

Used only if ``ssl:certs`` is defined.

.. _pillar-ssl-expiry_days:

ssl:expiry_days
~~~~~~~~~~~~~~~

Warning if the number of days until the SSL certificate expires less than given
days.

Default: ``15``.

Used only if ``{{ appname }}:ssl`` is turned on.

.. _pillar-ssl-certs-domain-letsencrypt:

ssl:certs:{{ domain }}:letsencrypt
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Indicates to get certificate from `Letsencrypt <http://letsencrypt.org/>_`
by using :doc:`/acmetool/doc/index`.
This is mutual exclusion with using certificates from pillar.

.. _pillar-ssl-certs-name-server_key:

ssl:certs:{{ name }}:server_key
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The server key.

Used only if ``ssl:certs`` is defined.

.. _pillar-ssl-certs-name-server_crt:

ssl:certs:{{ name }}:server_crt
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The server certificate.

Used only if ``ssl:certs`` is defined.

.. _pillar-ssl-certs-name-ca_crt:

ssl:certs:{{ name }}:ca_crt
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The CA certificate.

Used only if ``ssl:certs`` is defined.
