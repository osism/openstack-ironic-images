#!/usr/bin/env bash

filename=/opt/info-$(/usr/sbin/dmidecode -s system-serial-number).txt

/usr/sbin/modprobe ipmi_devintf || true
/usr/sbin/modprobe ipmi_si || true

echo "#" | tee -a ${filename// /_}
echo "# OUTPUT: IPMITOOL" | tee -a ${filename// /_}
echo "#" | tee -a ${filename// /_}

if [[ -e /dev/ipmi0 ]]; then
    /usr/bin/ipmitool lan print | tee -a ${filename// /_}
fi

echo "#" | tee -a ${filename// /_}
echo "# OUTPUT: SERIALNUMBER" | tee -a ${filename// /_}
echo "#" | tee -a ${filename// /_}

/usr/sbin/dmidecode -s system-serial-number | tee -a ${filename// /_}

echo "#" | tee -a ${filename// /_}
echo "# OUTPUT: DMIDECODE" | tee -a ${filename// /_}
echo "#" | tee -a ${filename// /_}

/usr/sbin/dmidecode | tee -a ${filename// /_}

echo "#" | tee -a ${filename// /_}
echo "# OUTPUT: IPROUTE " | tee -a ${filename// /_}
echo "#" | tee -a ${filename// /_}

/usr/bin/ip l | tee -a ${filename// /_}

echo "#" | tee -a ${filename// /_}
echo "# OUTPUT: BLOCKDEVICES" | tee -a ${filename// /_}
echo "#" | tee -a ${filename// /_}

/usr/bin/lsblk | tee -a ${filename// /_}

echo "#" | tee -a ${filename// /_}
echo "# OUTPUT: PCI" | tee -a ${filename// /_}
echo "#" | tee -a ${filename// /_}

/usr/bin/lspci -v | tee -a ${filename// /_}

echo "#" | tee -a ${filename// /_}
echo "# OUTPUT: ETHTOOL" | tee -a ${filename// /_}
echo "#" | tee -a ${filename// /_}

for iface in $(ls /sys/class/net/ | grep -v lo); do
    ethtool "$iface" | tee -a ${filename// /_}
done
