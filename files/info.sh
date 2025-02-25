#!/usr/bin/env bash

mkdir -p /opt/info

max=0
for file in /opt/info/*; do
    name=$(basename "$file")
    if [[ $name =~ ^[0-9]+$ ]]; then
        if (( name > max )); then
            max=$name
        fi
    fi
done
next=$((max + 1))

/usr/sbin/dmidecode -s system-serial-number | tee -a /opt/info/$next
/usr/sbin/dmidecode | tee -a /opt/info/$next
/usr/bin/ip l | tee -a /opt/info/$next
/usr/bin/lsblk | tee -a /opt/info/$next
/usr/bin/lspci -v | tee -a /opt/info/$next
