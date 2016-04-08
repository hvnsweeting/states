Upgrade
-------

0. Backup the current running VMs by exporting or taking snapshot.

1. Turn off the VMs:

.. code-block:: bash

   salt -L
   tap3-dot-net-W81-64,tap2-windows-8-1-pro,tap5-qtorrent-W81-64,bookya-api-ci-1,cats-android-1,cats-btcd-1,tap17-windows-go-build,cats-wincrossbuild
   system.poweroff -l debug

2. Upgrade the kernel:

.. code-block:: bash

   apt-get install --install-recommends linux-generic-lts-wily

3. Reboot:

.. code-block:: bash

   reboot

4. Reinstall the VirtualBox kernel modules:

.. code-block:: bash

   /etc/init.d/vboxdrv setup

5. Start the VMs:

.. code-block:: bash

   start virtualbox-autostart
