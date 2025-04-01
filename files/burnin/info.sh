#!/usr/bin/env bash

filename=/opt/info-$(/usr/sbin/dmidecode -s system-serial-number).txt

/usr/sbin/modprobe ipmi_devintf || true
/usr/sbin/modprobe ipmi_si || true

if [[ -e /dev/ipmi0 ]]; then
    /usr/bin/ipmitool lan print | tee -a ${filename// /_}
fi

/usr/sbin/dmidecode -s system-serial-number | tee -a ${filename// /_}
/usr/sbin/dmidecode | tee -a ${filename// /_}
/usr/bin/ip l | tee -a ${filename// /_}
/usr/bin/lsblk | tee -a ${filename// /_}
/usr/bin/lspci -v | tee -a ${filename// /_}
