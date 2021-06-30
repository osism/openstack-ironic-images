#!/bin/sh -eux

echo "set new Defaults"
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=sudo' /etc/sudoers;

echo "Set up password-less sudo for the install user"
echo 'install ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/99_install;
chmod 440 /etc/sudoers.d/99_install;
