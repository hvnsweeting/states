Usage
=====

For complete :doc:`index` manual, visit:
https://www.virtualbox.org/manual/UserManual.html

.. _virtualbox-usage-remote-installing-in-a-headless-server:

Remote installing in a headless server
--------------------------------------

1. Creating new VM machine:

.. code-block:: bash

   vboxmanage createvm --name "Windows7-dev" --ostype "Windows7" --register

   To get a complete list of supported operating systems use:

.. code-block:: bash

   vboxmanage list ostypes


2. Set appropirate settings for the newly created VM.

.. code-block:: bash

   vboxmanage modifyvm "Windows7-dev" --memory 1024 --vram 128 --acpi on --boot1 dvd --nic1 bridged --bridgeadapter1 eth0

3. Create a virtual hard disk for the VM

.. code-block:: bash

   vboxmanage createhd --filename "Windows7-dev.vdi" --size 10000

4. Add a SATA controller for OS hard disk

.. code-block:: bash

   vboxmanage storagectl "Windows7-dev" --name "SATA Controller" --add sata --controller IntelAHCI
   vboxmanage storageattach "Windows7-dev" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "Windows7-dev.vdi"

5. Add a IDE controller for DVD drive

.. code-block:: bash

   vboxmanage storagectl "Windows7-dev" --name "IDE Controller" --add ide
   vboxmanage storageattach "Windows7-dev" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium /path/to/windows7-install.iso

6. Start VM

.. code-block:: bash

   vboxheadless -s "Windows7-dev" -e "TCP/Ports"="3389"

.. warning::

   with above command, connect to the VM will not require authentication.  It's
   recommended to only allow trusted machines access above port, or
   `setup authentication <https://www.virtualbox.org/manual/ch07.html#vbox-auth>`_.

7. Use a RDP client to connect to VM. In Linux machine, `rdesktop` program can
   be used for this purpose.

.. code-block:: bash

   rdesktop {{ virtualbox-host-ip }}:3389

   Now the VM can be installed as normal.

Create VM from Appliance
------------------------

Installing VM from ISO file can be time consuming, developer can export the VM
from their development machine (laptop, desktop) and import in :doc:`index` host
instead.

For Windows, Microsoft provides `VM images <http://dev.modern.ie/tools/vms/>`_
for testing purpose.

Assume that we have a Windows VM image named `E11 - Win7.ova`.

1. Import image

.. code-block:: bash

   vboxmanage import "IE11 - Win7.ova" --vsys 0 --vmname "Win7-IE11" --memory 1024

2. Config machine to use host-only networking (optional)

.. code-block:: bash

   vboxmanage modifyvm "Win7-IE11" --nic1 hostonly --hostonlyadapter1 tap1

Remember to use the appropriate network interface (``tap1`` in example
above). It is a good practice to name the VM with the interface they use, for
example ``tap1-win7-ie11``.

3. Start VM

.. code-block:: bash

   vboxheadless -s "Win7-IE11" -e "TCP/Ports"="3389"

Same warning applies likes starting VM with
:ref:`virtualbox-usage-remote-installing-in-a-headless-server`.

Adding new partition
--------------------

1. Listing to get name of target VM


.. code-block:: bash

    vboxmanage list vms

Says, targeted VM called my_vm.

2. Listing to get HDD UUID

.. code-block:: bash

    vboxmanage list hdds

3. Stop my_vm

.. code-block:: bash

    vboxmanage controlvm my_vm poweroff soft

4. Cloning to VDI image format if it is using different format

.. code-block:: bash

    VBoxManage clonehd <infilename or UUID> <outfilename> --format VDI --variant Standard

5. Resize disk

.. code-block:: bash

    VBoxManage modifyhd <absolute path to file> --resize <size in MB>

6. Replace old HDD with new, resized one

.. code-block:: bash

    VBoxManage storageattach my_vm --storagectl SATA --device 0 --port 0 --type hdd --medium new_disk.VDI

7. Turn on the VM

.. code-block:: bash

    VBoxManage startvm my_vm --type headless

8. Then using fdisk/parted to re-partitioning the hard disk.
