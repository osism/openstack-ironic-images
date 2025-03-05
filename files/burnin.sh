#!/usr/bin/env bash

NUMBER_OF_CPUS=$(nproc --all)

filename=/opt/burnin-$(/usr/sbin/dmidecode -s system-serial-number).txt

if [[ -e /opt/timeout ]]; then
    TIMEOUT=$(</opt/timeout)
else
    TIMEOUT=43200s
fi

/usr/sbin/dmidecode -s system-serial-number | tee -a ${filename// /_}
/usr/bin/stress-ng --cpu $NUMBER_OF_CPUS --timeout $TIMEOUT | tee -a ${filename// /_}
/usr/bin/stress-ng --vm 1 --vm-bytes 80% --vm-method all --verify --timeout $TIMEOUT | tee -a ${filename// /_}
