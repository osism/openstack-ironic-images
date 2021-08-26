#!/bin/env bash
# FIXME (mueller): do this with sfdisk or parted

fdisk /dev/sda << FDISK
d
2
n
e
2
1001470

n


x
b
5
1001472
r
t
5
8e
w
FDISK

# partprobe and pvresize
partprobe /dev/sda
pvresize /dev/sda5