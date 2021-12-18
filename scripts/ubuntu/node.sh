#!/usr/bin/env bash

# NOTE: Because DNS queries don't always work directly at the beginning a
#       retry for APT.
echo "set apt retry"
echo "APT::Acquire::Retries \"3\";" > /etc/apt/apt.conf.d/80-retries

echo "set restart-without-asking to true"
echo '* libraries/restart-without-asking boolean true' | debconf-set-selections

echo "apt-get update"
apt-get update

echo "set frontend to Noninteractive to supress 'debconf: unable to initialize frontend' - messages"
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

echo "install packages"
apt-get install --yes \
  ifupdown \
  python3-pip \
  python3-argcomplete \
  python3-crypto \
  python3-dnspython \
  python3-jmespath \
  python3-kerberos \
  python3-libcloud \
  python3-lockfile \
  python3-netaddr \
  python3-ntlm-auth \
  python3-requests-kerberos \
  python3-requests-ntlm \
  python3-selinux \
  python3-winrm \
  python3-xmltodict \
  htop \
  vim \
  bridge-utils \
  ifenslave \
  ifupdown \
  vlan \
  gnupg \
  cloud-init \
  cloud-guest-utils \
  cloud-initramfs-copymods \
  cloud-initramfs-dyn-netconf \
  git

# cloud init config
echo "cloud init config"
for i in cloud-init systemd-networkd-wait-online.service; do
  systemctl enable $i
done
ln -s /lib/systemd/system/cloud-init.target /etc/systemd/system/multi-user.target.wants/cloud-init.target

# configure netplan
echo "netplan config"
mv /home/install/01-netcfg.yaml /etc/netplan/01-netcfg.yaml

# NOTE: There are cloud images on which Ansible is pre-installed.
echo "remove ansible package"
apt-get remove --yes ansible

echo "install ansible via pip3"
pip3 install --no-cache-dir 'ansible>=2.10'

echo "mkdir /usr/share/ansible for collections"
mkdir -p /usr/share/ansible

echo "install collections"
/usr/local/bin/ansible-galaxy collection install --collections-path /usr/share/ansible/collections ansible.netcommon
/usr/local/bin/ansible-galaxy collection install --collections-path /usr/share/ansible/collections git+https://github.com/osism/ansible-collection-commons.git
/usr/local/bin/ansible-galaxy collection install --collections-path /usr/share/ansible/collections git+https://github.com/osism/ansible-collection-services.git

chmod -R +r /usr/share/ansible

echo "ansible-playbook node.yml"
/usr/local/bin/ansible-playbook -i localhost, /home/install/node.yml
