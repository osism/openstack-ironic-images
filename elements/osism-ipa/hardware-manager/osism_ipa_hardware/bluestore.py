# SPDX-License-Identifier: Apache-2.0

"""Find and zero BlueStore label copies on a block device.

BlueStore writes its label at offsets 0, 1, 10, 100 and 1000 GiB of the
OSD's main device (bdev_label_positions in Ceph's BlueStore.cc), and
ceph-volume refuses a device that carries any of them.
"""

import errno
import mmap
import os

GiB = 1 << 30
MiB = 1 << 20

LABEL_OFFSETS = (0, 1 * GiB, 10 * GiB, 100 * GiB, 1000 * GiB)
LABEL_SIZE = 4096
MAGIC = b"bluestore block device\n"
_UUID_LEN = 36


def _open(path, flags):
    # O_DIRECT keeps reads through a disk and through an LV on it from
    # seeing each other's stale page cache. Fall back for files in tests.
    try:
        return os.open(path, flags | os.O_DIRECT)
    except OSError as e:
        if e.errno != errno.EINVAL:
            raise
        return os.open(path, flags)


def find_labels(path, bases=(0,)):
    """Return sorted (position, osd_uuid) for each label found on path.

    Each base is the start of a possible BlueStore device on path; the
    label offsets are relative to it.
    """
    found = {}
    buf = mmap.mmap(-1, LABEL_SIZE)
    fd = _open(path, os.O_RDONLY)
    try:
        size = os.lseek(fd, 0, os.SEEK_END)
        for base in bases:
            for offset in LABEL_OFFSETS:
                pos = base + offset
                if pos + LABEL_SIZE > size:
                    continue
                if os.preadv(fd, [buf], pos) != LABEL_SIZE:
                    continue
                if buf[: len(MAGIC)] == MAGIC:
                    raw = buf[len(MAGIC) : len(MAGIC) + _UUID_LEN]
                    found[pos] = raw.decode("ascii", "replace")
    finally:
        os.close(fd)
        buf.close()
    return sorted(found.items())


def zero_labels(path, positions):
    """Overwrite one label block with zeros at each position."""
    if not positions:
        return
    zeros = mmap.mmap(-1, LABEL_SIZE)
    fd = _open(path, os.O_WRONLY)
    try:
        for pos in positions:
            if os.pwritev(fd, [zeros], pos) != LABEL_SIZE:
                raise OSError(errno.EIO, "short write at %d" % pos, path)
        os.fsync(fd)
    finally:
        os.close(fd)
        zeros.close()
