#!/usr/bin/env bash

NUMBER_OF_CPUS=$(nproc --all)

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
/usr/bin/stress-ng --vm 1 --vm-bytes 80% --vm-method all --verify --timeout 600s | tee -a /opt/burnin/$next
