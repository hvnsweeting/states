Usage
=====

Linux
-----

1. Install PPTP client:

.. code-block:: bash

    apt-get install pptp-linux

2. Create or add lines to the ``/etc/ppp/chap-secrets`` file, which holds
   usernames and passwords:

.. code-block:: bash

    # client        server  secret                  IP addresses
    username        *       password                *

3. Try to connect from the command line:

.. code-block:: bash

    pppd remotename pptp linkname pptp ipparam pptp pty "pptp IP.OF.PPTP.SERVER
    --nolaunchpppd" name username usepeerdns refuse-pap refuse-chap
    refuse-mschap require-mppe-128 require-mschap-v2 noauth debug dump logfd 2
    nodetach

If everything is OK:

.. code-block:: bash

    local  IP address 172.16.0.2
    remote IP address 172.16.0.1
    primary   DNS address 172.16.0.1
    secondary DNS address 172.16.0.1
    Script /etc/ppp/ip-up started (pid 21796)
    Script /etc/ppp/ip-up finished (pid 21796), status = 0x0
