#!/bin/sh -eux

# should output one of 'redhat' 'centos' 'oraclelinux'
distro="`rpm -qf --queryformat '%{NAME}' /etc/redhat-release | cut -f 1 -d '-'`"
major_version="`sed 's/^.\+ release \([.0-9]\+\).*/\1/' /etc/redhat-release | awk -F. '{print $1}'`";

echo "reduce the grub menu time to 1 second"
if ! [ "$major_version" -eq 6 ]; then
  sed -i -e 's/^GRUB_TIMEOUT=[0-9]\+$/GRUB_TIMEOUT=1/' /etc/default/grub
  grub2-mkconfig -o /boot/grub2/grub.cfg
fi

# make sure we use dnf on EL 8+
if [ "$major_version" -ge 8 ]; then
  pkg_cmd="dnf"
else
  pkg_cmd="yum"
fi

echo "Remove development and kernel source packages"
$pkg_cmd -y remove gcc cpp gc kernel-devel kernel-headers glibc-devel elfutils-libelf-devel glibc-headers kernel-devel kernel-headers

if [ "$major_version" -ge 8 ]; then
  echo "remove orphaned packages"
  dnf -y autoremove
  echo "Remove previous kernels that preserved for rollbacks"
  dnf -y remove -y $(dnf repoquery --installonly --latest-limit=-1 -q)
else
  echo "Remove previous kernels that preserved for rollbacks"
  if ! command -v package-cleanup >/dev/null 2>&1; then
    yum -y install yum-utils
  fi
  package-cleanup --oldkernels --count=1 -y
fi

# Avoid ~200 meg firmware package we don't need
# this cannot be done in the KS file so we do it here
echo "Removing extra firmware packages"
$pkg_cmd -y remove linux-firmware

if [ "$distro" != 'redhat' ]; then
  echo "clean all package cache information"
  $pkg_cmd -y clean all  --enablerepo=\*;
fi

# Clean up network interface persistence
rm -f /etc/udev/rules.d/70-persistent-net.rules;
#mkdir -p /etc/udev/rules.d/70-persistent-net.rules;
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules;
rm -rf /dev/.udev/;

for ndev in `ls -1 /etc/sysconfig/network-scripts/ifcfg-*`; do
    if [ "`basename $ndev`" != "ifcfg-lo" ]; then
        sed -i '/^HWADDR/d' "$ndev";
        sed -i '/^UUID/d' "$ndev";
    fi
done

echo "truncate any logs that have built up during the install"
find /var/log -type f -exec truncate --size=0 {} \;

echo "remove the install log"
rm -f /root/anaconda-ks.cfg /root/original-ks.cfg

echo "remove the contents of /tmp and /var/tmp"
rm -rf /tmp/* /var/tmp/*

if [ "$major_version" -ge 7 ]; then
  echo "Force a new random seed to be generated"
  rm -f /var/lib/systemd/random-seed

  echo "Wipe netplan machine-id (DUID) so machines get unique ID generated on boot"
  truncate -s 0 /etc/machine-id
fi

echo "Clear the history so our install commands aren't there"
rm -f /root/.wget-hsts
export HISTSIZE=0

echo "remove floppy entry in fstab"
sed -i '/floppy/d' /etc/fstab

echo "ansible-playbook cleanup.yml"
/usr/local/bin/ansible-playbook -i localhost, /home/install/cleanup.yml

echo "remove provisioner scripts"
for i in cleanup Debian node RedHat cleanup-RedHat cleanup-Debian; do rm /home/install/${i}.yml; done

echo "remove .ansible directory for user install, created during ansible runs in node.sh and cleanup.sh"
rm -rf /home/install/.ansible
