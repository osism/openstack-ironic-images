#!/usr/bin/env bash

NUMBER_OF_CPUS=$(nproc --all)

filename=/opt/burnin-$(/usr/sbin/dmidecode -s system-serial-number).txt

/usr/sbin/dmidecode -s system-serial-number | tee -a ${filename// /_}
/usr/bin/stress-ng --cpu $NUMBER_OF_CPUS --timeout 43200s | tee -a ${filename// /_}
/usr/bin/stress-ng --vm 1 --vm-bytes 80% --vm-method all --verify --timeout 43200s | tee -a ${filename// /_}
