#!/bin/env bash
# FIXME (mueller): do this with sfdisk or parted

fdisk /dev/sda << FDISK
d
2
n
2
999424

n


t
2
31
w
FDISK

# partprobe and pvresize
partprobe /dev/sda
pvresize /dev/sda2