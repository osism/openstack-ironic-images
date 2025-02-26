#!/usr/bin/env bash

filename=/opt/info-$(/usr/sbin/dmidecode -s system-serial-number).txt

/usr/sbin/dmidecode -s system-serial-number | tee -a ${filename// /_}
/usr/sbin/dmidecode | tee -a ${filename// /_}
/usr/bin/ip l | tee -a ${filename// /_}
/usr/bin/lsblk | tee -a ${filename// /_}
/usr/bin/lspci -v | tee -a ${filename// /_}
