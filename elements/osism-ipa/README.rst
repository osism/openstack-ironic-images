======================================
OSISM custom setup for IPA with L3 FRR
======================================

Sets up FRR with BGP over IPv6 unnumbered interfaces
creating BGP sessions over all found ethernet interfaces.

Erasing BlueStore labels
========================

``hardware-manager/`` is an ironic-python-agent hardware manager, installed
into IPA's virtualenv. It takes over the ``erase_devices_metadata`` and
``erase_devices_express`` steps: before the generic erase runs, it zeroes
the BlueStore labels (at 0, 1, 10, 100 and 1000 GiB of an OSD device) on
every device the erase covers, looking through active LVs and at the
start of each disk and partition. Without this, the label copies survive
a metadata erase and ceph-volume refuses the disk once LVM rebuilds the
same layout.

Run its tests in a virtualenv with ironic-python-agent and pytest
installed::

    pip install ./hardware-manager
    cd hardware-manager && pytest tests
