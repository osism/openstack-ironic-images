#!/usr/bin/env bash

# NOTE: Because DNS queries don't always work directly at the beginning a
#       retry for APT.

echo "install epel"
dnf --assumeyes install epel-release

echo "dnf update"
dnf --assumeyes update

echo "install packages"
dnf install --assumeyes \
  python38-debug \
  python38-pip \
  python3-argcomplete \
  python3-jmespath \
  python3-kerberos \
  python3-lockfile \
  python3-netaddr \
  python3-requests-kerberos \
  python3-libselinux \
  python3-xmltodict \
  htop \
  vim \
  bridge-utils \
  gnupg2 \
  cloud-init \
  git \
  gcc

# cloud init config
echo "cloud init config"
systemctl enable cloud-init
ln -s /lib/systemd/system/cloud-init.target /etc/systemd/system/multi-user.target.wants/cloud-init.target

# NOTE: There are cloud images on which Ansible is pre-installed.
echo "remove ansible package"
dnf remove --assumeyes ansible

echo "install dependencies via pip3.8"
pip3.8 install --no-cache-dir 'pycrypto' 'dnspython' 'apache-libcloud' 'ntlm-auth' 'requests_ntlm' 'pywinrm'

echo "install ansible via pip3.8"
pip3.8 install --no-cache-dir 'ansible>=2.10'

echo "mkdir /usr/share/ansible for collections"
mkdir -p /usr/share/ansible

echo "install collections"
/usr/local/bin/ansible-galaxy collection install --collections-path /usr/share/ansible/collections ansible.netcommon
/usr/local/bin/ansible-galaxy collection install --collections-path /usr/share/ansible/collections git+https://github.com/osism/ansible-collection-commons.git
/usr/local/bin/ansible-galaxy collection install --collections-path /usr/share/ansible/collections git+https://github.com/osism/ansible-collection-services.git

chmod -R +r /usr/share/ansible

echo "ansible-playbook node.yml"
/usr/local/bin/ansible-playbook -i localhost, /home/install/node.yml
