#!/usr/bin/env bash

NUMBER_OF_CPUS=$(nproc --all)
MEMTOTAL=$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 - 32768 }')

mkdir -p /opt/burnin

max=0
for file in /opt/burnin/*; do
    name=$(basename "$file")
    if [[ $name =~ ^[0-9]+$ ]]; then
        if (( name > max )); then
            max=$name
        fi
    fi
done
next=$((max + 1))

/usr/sbin/dmidecode -s system-serial-number | tee -a /opt/burnin/$next
/usr/bin/stress-ng --cpu $NUMBER_OF_CPUS --timeout 600s | tee -a /opt/burnin/$next
/usr/bin/stress-ng --vm 1 --vm-bytes ${MEMTOTAL}k --vm-method all --verify --timeout 600s | tee -a /opt/burnin/$next
/usr/sbin/memtester ${MEMTOTAL}k 1 | tee -a /opt/burnin/$next
