#!/bin/sh -eux

echo "set new Defaults"
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=sudo' /etc/sudoers;

echo "Set up password-less sudo for the centos user"
echo 'centos ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/99_centos;
chmod 440 /etc/sudoers.d/99_centos;
