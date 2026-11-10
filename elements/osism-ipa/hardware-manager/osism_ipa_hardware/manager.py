# SPDX-License-Identifier: Apache-2.0

"""IPA hardware manager that makes the metadata erase Ceph-proof.

IPA's metadata erase (wipefs, the first and last sectors, the partition
tables) leaves BlueStore's label copies at 1, 10, 100 and 1000 GiB. Once
LVM rebuilds the same layout, ceph-volume refuses the new LV because of
them. This manager takes over erase_devices_metadata and
erase_devices_express, zeroes the label copies on every device the erase
covers, and then hands over to the generic implementation.
"""

import json
import os

from ironic_python_agent import errors
from ironic_python_agent import hardware
from ironic_python_agent import utils
from oslo_concurrency import processutils
from oslo_log import log

from osism_ipa_hardware import bluestore

LOG = log.getLogger(__name__)

# Where a BlueStore device may start on a disk or partition: at its start
# (raw OSD) or at LVM's default data start, for an LV whose LVM metadata
# an earlier erase already removed.
_RAW_BASES = (0, bluestore.MiB)


class OsismHardwareManager(hardware.HardwareManager):
    HARDWARE_MANAGER_NAME = "OsismHardwareManager"
    HARDWARE_MANAGER_VERSION = "1.0"

    def evaluate_hardware_support(self):
        # Above GenericHardwareManager (MAINLINE), so the erase steps below
        # are dispatched here.
        return hardware.HardwareSupport.SERVICE_PROVIDER

    def erase_devices_metadata(self, node, ports):
        generic = _generic_manager()
        erase_bluestore_labels(generic, node)
        return generic.erase_devices_metadata(node, ports)

    def erase_devices_express(self, node, ports):
        generic = _generic_manager()
        erase_bluestore_labels(generic, node)
        return generic.erase_devices_express(node, ports)


def _generic_manager():
    for manager in hardware.get_managers():
        if isinstance(manager, hardware.GenericHardwareManager):
            return manager
    raise errors.IncompatibleHardwareMethodError("GenericHardwareManager is not loaded")


def erase_bluestore_labels(generic, node):
    """Zero BlueStore labels on the devices the generic erase will cover."""
    devices = generic._list_erasable_devices(node)
    if not devices:
        return
    for dev in devices:
        hardware.safety_check_block_device(node, dev.name)
    erasable = {dev.name for dev in devices}

    targets = []
    activated, lv_paths = _activate_lvs()
    try:
        for lv_path in lv_paths:
            if _covered(os.path.basename(os.path.realpath(lv_path)), erasable):
                targets.append((lv_path, (0,)))
            else:
                LOG.info(
                    "Not checking %s for BlueStore labels: it uses devices "
                    "outside the erase",
                    lv_path,
                )
        targets.extend((dev.name, _RAW_BASES) for dev in devices)

        failed = {}
        for path, bases in targets:
            try:
                labels = bluestore.find_labels(path, bases)
                for pos, osd_uuid in labels:
                    LOG.info(
                        "Zeroing BlueStore label of OSD %s on %s at byte %d",
                        osd_uuid,
                        path,
                        pos,
                    )
                bluestore.zero_labels(path, [pos for pos, _ in labels])
            except OSError as e:
                LOG.error("Failed to erase BlueStore labels on %s: %s", path, e)
                failed[path] = e
    finally:
        _deactivate_lvs(activated)

    if failed:
        raise errors.BlockDeviceEraseError(
            "Failed to erase BlueStore labels on: %s"
            % "; ".join('"%s": %s' % item for item in failed.items())
        )


def _covered(name, erasable):
    """Whether block device name sits only on erasable devices."""
    if "/dev/" + name in erasable:
        return True
    try:
        slaves = os.listdir("/sys/class/block/%s/slaves" % name)
    except OSError:
        return False
    return bool(slaves) and all(_covered(s, erasable) for s in slaves)


def _lvs():
    """Map each LV's full name to its device-mapper path."""
    out, _ = utils.execute(
        "lvs",
        "--reportformat",
        "json",
        "-o",
        "lv_full_name,lv_dm_path",
    )
    report = json.loads(out)["report"]
    return {
        lv["lv_full_name"]: lv["lv_dm_path"]
        for section in report
        for lv in section.get("lv", [])
    }


def _active_lvs():
    return {n: p for n, p in _lvs().items() if os.path.exists(p)}


def _activate_lvs():
    """Activate every LV it can.

    :returns: the names of the LVs it activated, and the device paths of
        all active LVs.
    """
    try:
        before = _active_lvs()
        # A VG with a missing PV fails to activate, which is not an error
        # here: its LVs stay inactive and the raw-device check covers them.
        utils.execute("vgchange", "-ay", check_exit_code=False)
        utils.execute("udevadm", "settle", check_exit_code=False)
        after = _active_lvs()
    except (processutils.ProcessExecutionError, OSError, ValueError) as e:
        LOG.warning("Cannot list or activate LVM volumes: %s", e)
        return set(), []
    return set(after) - set(before), sorted(after.values())


def _deactivate_lvs(names):
    for name in sorted(names):
        try:
            utils.execute("lvchange", "-an", name)
        except (processutils.ProcessExecutionError, OSError) as e:
            LOG.warning("Failed to deactivate %s: %s", name, e)
