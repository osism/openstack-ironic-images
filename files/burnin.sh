#!/usr/bin/env bash

NUMBER_OF_CPUS=$(nproc --all)
MEMTOTAL=$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 - 32768 }')

/usr/bin/stress-ng --cpu $NUMBER_OF_CPUS --timeout 600s
/usr/bin/stress-ng --vm 1 --vm-bytes ${MEMTOTAL}k --vm-method all --verify --timeout 600s
/usr/sbin/memtester ${MEMTOTAL}k 1
