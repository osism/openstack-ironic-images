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

# NOTE: There are cloud images on which Ansible is pre-installed.
echo "remove ansible package"
dnf remove --assumeyes ansible

echo "install dependencies via pip3.8"
pip3.8 install --no-cache-dir 'pycrypto' 'dnspython' 'apache-libcloud' 'ntlm-auth' 'requests_ntlm' 'pywinrm'

echo "install ansible via pip3.8"
pip3.8 install --no-cache-dir 'ansible>=2.10'

echo "create autorized_keys"
mkdir -p /home/install/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDbQhGsHpRbK06skYIGTOB/iPrbTGL3j+O2Wvy9sEhWM4uSudmMWVeDePElS5BWiLWTgQeHZX67zBY/WsbZ71XmU3qOozanvF/Uw82bTabRaO7FVWi+b6IPslWhgtQayA0ea+uNK/+dUGCnZ42wznugSb7MuVUfyMUMgHjGVluEwNB6HW+4P8uw8PhX5ssPBd2fO0SB9zkMm8zIPPVAsuogfbq9uTh+LOfhs5xyaxevGKq395YUO9Ne2sOart2JjTmBVhyf6plAJgKHGRnGY4QRP/YIlTO5d/mdF15sFTXcljpYZEDdO157HXoWIcMNGGTxLwYpX8KrD1JUmeTgK7g7bCnDpTvBsoKBrsHHEKp3BPvHk/wE3pEcbFIwC7E+7AVyhoG12oO09QRHtBTuDbuBqlO09dnFBKc+Y/Gd0RNi1HYkJk3Bt7TSY0+TKsp4d5XLPqFYuhNQlmPf0lIkFwU1GJe47RCp2TjjMn31ZQFzLke+EMqEcBB1ebtWFmZcoiWX7vb4jiQWeYg6cRj89jNQm7PUWnHMzQ1eAw9lbzfjFYoVwLx6/HVsdaKp1tpysChXqNRlOwaQMACh1hxxDPpVf2Jt1143P8u0IiZ08z51AfLUOekgzee4Iilv8xJPXxi7ajep1zcOtJalLaqT9Cey6/DV1B/bp0Fez4UfzSYnbw==" > /home/install/.ssh/authorized_keys
cp /home/install/.ssh/authorized_keys /home/install/.ssh/id_rsa.pub
chown -R install:install /home/install/.ssh
chmod 0700 /home/install/.ssh
chmod 0600 /home/install/.ssh/authorized_keys
chmod 0644 /home/install/.ssh/id_rsa.pub

echo "mkdir /usr/share/ansible for collections"
mkdir -p /usr/share/ansible

echo "install collections"
/usr/local/bin/ansible-galaxy collection install --collections-path /usr/share/ansible/collections ansible.netcommon
/usr/local/bin/ansible-galaxy collection install --collections-path /usr/share/ansible/collections git+https://github.com/osism/ansible-collection-commons.git
/usr/local/bin/ansible-galaxy collection install --collections-path /usr/share/ansible/collections git+https://github.com/osism/ansible-collection-services.git

chmod -R +r /usr/share/ansible

echo "ansible-playbook node.yml"
/usr/local/bin/ansible-playbook -i localhost, /home/install/node.yml
