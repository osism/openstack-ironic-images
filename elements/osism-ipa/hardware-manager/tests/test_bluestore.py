# SPDX-License-Identifier: Apache-2.0

import os

import pytest

from osism_ipa_hardware import bluestore

GiB = bluestore.GiB
MiB = bluestore.MiB
UUID = "0d1c4f9e-6a3b-4c5d-8e7f-0123456789ab"


def label(osd_uuid=UUID):
    data = bluestore.MAGIC + osd_uuid.encode() + b"\n"
    return data.ljust(bluestore.LABEL_SIZE, b"\x01")


@pytest.fixture
def disk(tmp_path):
    """A sparse 1001 GiB file standing in for a disk."""
    path = tmp_path / "disk"
    with open(path, "wb") as f:
        f.truncate(1001 * GiB)
    return str(path)


def write(path, pos, data):
    with open(path, "r+b") as f:
        f.seek(pos)
        f.write(data)


def read(path, pos, size=bluestore.LABEL_SIZE):
    with open(path, "rb") as f:
        f.seek(pos)
        return f.read(size)


def test_finds_copies_relative_to_each_base(disk):
    # An old LV at LVM's default data start, as on dg: the label at 0 of
    # the LV is gone, the copies remain.
    for off in bluestore.LABEL_OFFSETS[1:]:
        write(disk, MiB + off, label())

    assert bluestore.find_labels(disk) == []
    assert bluestore.find_labels(disk, (0, MiB)) == [
        (MiB + off, UUID) for off in bluestore.LABEL_OFFSETS[1:]
    ]


def test_ignores_other_data_at_label_offsets(disk):
    write(disk, 10 * GiB, b"bluestore block devic" + b"x" * 4075)
    write(disk, 0, b"\x00" * 4096)
    assert bluestore.find_labels(disk) == []


def test_skips_offsets_beyond_the_device(tmp_path):
    path = str(tmp_path / "small")
    with open(path, "wb") as f:
        f.truncate(2 * GiB)
    write(path, GiB, label())
    assert bluestore.find_labels(path, (0, MiB)) == [(GiB, UUID)]


def test_zero_labels_clears_only_the_label_blocks(disk):
    write(disk, 100 * GiB - 1, b"\x02")
    write(disk, 100 * GiB, label())
    write(disk, 100 * GiB + bluestore.LABEL_SIZE, b"\x03")

    bluestore.zero_labels(disk, [100 * GiB])

    assert read(disk, 100 * GiB) == b"\x00" * bluestore.LABEL_SIZE
    assert read(disk, 100 * GiB - 1, 1) == b"\x02"
    assert read(disk, 100 * GiB + bluestore.LABEL_SIZE, 1) == b"\x03"
    assert bluestore.find_labels(disk) == []


def test_zero_labels_without_positions_does_not_open(tmp_path):
    bluestore.zero_labels(os.fspath(tmp_path / "missing"), [])
