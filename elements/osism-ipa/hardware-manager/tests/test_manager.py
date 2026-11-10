# SPDX-License-Identifier: Apache-2.0

import json
from unittest import mock

# Registers IPA's options; the agent imports it before loading managers.
from ironic_python_agent import config  # noqa: F401
from ironic_python_agent import errors
from ironic_python_agent import hardware
import pytest

from osism_ipa_hardware import bluestore
from osism_ipa_hardware import manager

NODE = {"uuid": "node-1", "properties": {}, "driver_internal_info": {}}


def dev(name):
    return hardware.BlockDevice(name, "model", 1, True)


def lvs_json(lvs):
    return json.dumps(
        {
            "report": [
                {"lv": [{"lv_full_name": n, "lv_dm_path": p} for n, p in lvs.items()]}
            ]
        }
    )


class FakeHost:
    """LVM, sysfs and dm paths as the manager sees them."""

    def __init__(self, lvs, active, slaves):
        self.lvs = lvs  # full name -> dm path
        self.active = set(active)  # full names
        self.slaves = slaves  # dm node -> slave names
        self.commands = []

    def execute(self, *cmd, **kwargs):
        self.commands.append(cmd)
        if cmd[0] == "lvs":
            return lvs_json(self.lvs), ""
        if cmd[:2] == ("vgchange", "-ay"):
            self.active = set(self.lvs)
        if cmd[:2] == ("lvchange", "-an"):
            self.active.discard(cmd[2])
        return "", ""

    def exists(self, path):
        return any(self.lvs[n] == path for n in self.active)

    def realpath(self, path):
        return "/dev/" + {p: d for d, p in self.dm_paths().items()}[path]

    def dm_paths(self):
        return {"dm-%d" % i: p for i, p in enumerate(sorted(self.lvs.values()))}

    def listdir(self, path):
        name = path.split("/")[4]
        if name not in self.slaves:
            raise FileNotFoundError(path)
        return self.slaves[name]


@pytest.fixture
def host():
    # dm-0: ceph-a/osd-block on sdb; dm-1: ceph-c/osd-block on sdc1,
    # inactive at boot; dm-2: other/lv on sdb and sdz (not erasable).
    lvs = {
        "ceph-a/osd-block": "/dev/mapper/ceph--a-osd--block",
        "other/lv": "/dev/mapper/other-lv",
        "ceph-c/osd-block": "/dev/mapper/ceph--c-osd--block",
    }
    slaves = {"dm-0": ["sdb"], "dm-1": ["sdc1"], "dm-2": ["sdb", "sdz"]}
    h = FakeHost(lvs, {"ceph-a/osd-block", "other/lv"}, slaves)
    with mock.patch.object(manager.utils, "execute", h.execute), mock.patch.object(
        manager.os.path, "exists", h.exists
    ), mock.patch.object(manager.os.path, "realpath", h.realpath), mock.patch.object(
        manager.os, "listdir", h.listdir
    ):
        yield h


@pytest.fixture
def generic():
    g = mock.Mock(spec=hardware.GenericHardwareManager)
    g._list_erasable_devices.return_value = [
        dev("/dev/sdc1"),
        dev("/dev/sdc"),
        dev("/dev/sdb"),
    ]
    with mock.patch.object(
        hardware,
        "get_managers",
        return_value=[manager.OsismHardwareManager(), g],
    ), mock.patch.object(hardware, "safety_check_block_device"):
        yield g


@pytest.fixture
def labels():
    found = {
        "/dev/mapper/ceph--a-osd--block": [(bluestore.GiB, "uuid-a")],
        "/dev/sdb": [(bluestore.MiB + 10 * bluestore.GiB, "uuid-old")],
    }
    with mock.patch.object(
        bluestore,
        "find_labels",
        side_effect=lambda path, bases: found.get(path, []),
    ) as find, mock.patch.object(bluestore, "zero_labels") as zero:
        yield find, zero


@pytest.mark.parametrize("step", ["erase_devices_metadata", "erase_devices_express"])
def test_zeroes_labels_then_runs_generic_step(host, generic, labels, step):
    find, zero = labels
    parent = mock.Mock()
    parent.attach_mock(zero, "zero")
    parent.attach_mock(getattr(generic, step), "generic")

    getattr(manager.OsismHardwareManager(), step)(NODE, [])

    checked = {c.args[0]: c.args[1] for c in find.call_args_list}
    assert checked == {
        "/dev/mapper/ceph--a-osd--block": (0,),
        "/dev/mapper/ceph--c-osd--block": (0,),
        "/dev/sdc1": (0, bluestore.MiB),
        "/dev/sdc": (0, bluestore.MiB),
        "/dev/sdb": (0, bluestore.MiB),
    }
    zeroed = {c.args[0]: c.args[1] for c in zero.call_args_list if c.args[1]}
    assert zeroed == {
        "/dev/mapper/ceph--a-osd--block": [bluestore.GiB],
        "/dev/sdb": [bluestore.MiB + 10 * bluestore.GiB],
    }
    # The generic erase runs last, with the same arguments.
    assert parent.mock_calls[-1] == mock.call.generic(NODE, [])


def test_restores_lv_activation(host, generic, labels):
    manager.OsismHardwareManager().erase_devices_metadata(NODE, [])
    assert ("lvchange", "-an", "ceph-c/osd-block") in host.commands
    assert host.active == {"ceph-a/osd-block", "other/lv"}


def test_lv_on_device_outside_the_erase_is_left_alone(host, generic, labels):
    find, _ = labels
    manager.OsismHardwareManager().erase_devices_metadata(NODE, [])
    paths = [c.args[0] for c in find.call_args_list]
    assert "/dev/mapper/other-lv" not in paths


def test_read_error_fails_the_step_before_the_generic_erase(host, generic, labels):
    find, _ = labels
    find.side_effect = OSError(5, "Input/output error")
    with pytest.raises(errors.BlockDeviceEraseError):
        manager.OsismHardwareManager().erase_devices_metadata(NODE, [])
    generic.erase_devices_metadata.assert_not_called()
    # The LV it activated is still deactivated.
    assert "ceph-c/osd-block" not in host.active


def test_without_lvm_tools_the_raw_devices_are_still_checked(generic, labels):
    find, _ = labels
    with mock.patch.object(
        manager.utils, "execute", side_effect=FileNotFoundError("lvs")
    ):
        manager.OsismHardwareManager().erase_devices_metadata(NODE, [])
    assert [c.args[0] for c in find.call_args_list] == [
        "/dev/sdc1",
        "/dev/sdc",
        "/dev/sdb",
    ]
    generic.erase_devices_metadata.assert_called_once_with(NODE, [])


def test_safety_check_runs_before_anything_is_written(host, generic, labels):
    _, zero = labels
    with mock.patch.object(
        hardware,
        "safety_check_block_device",
        side_effect=errors.ProtectedDeviceError(device="/dev/sdb", what="gpfs"),
    ):
        with pytest.raises(errors.ProtectedDeviceError):
            manager.OsismHardwareManager().erase_devices_metadata(NODE, [])
    zero.assert_not_called()
    generic.erase_devices_metadata.assert_not_called()


def test_no_erasable_devices_still_runs_generic(host, generic, labels):
    find, _ = labels
    generic._list_erasable_devices.return_value = []
    manager.OsismHardwareManager().erase_devices_metadata(NODE, [])
    find.assert_not_called()
    generic.erase_devices_metadata.assert_called_once_with(NODE, [])


def test_wins_dispatch_over_the_generic_manager():
    # The real entry point and IPA's real dispatch: the step goes here.
    with mock.patch.object(
        hardware.GenericHardwareManager,
        "evaluate_hardware_support",
        return_value=hardware.HardwareSupport.MAINLINE,
    ), mock.patch.object(hardware, "_global_managers", None), mock.patch.object(
        manager.OsismHardwareManager,
        "erase_devices_metadata",
        return_value="osism",
    ):
        names = [m.__class__.__name__ for m in hardware.get_managers()]
        assert names.index("OsismHardwareManager") < names.index(
            "GenericHardwareManager"
        )
        assert (
            hardware.dispatch_to_managers("erase_devices_metadata", NODE, []) == "osism"
        )
