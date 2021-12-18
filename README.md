# openstack-ironic-images

This repository is used to manage build recipes for creating images for use on baremetal systems.

| ID  | OS         | Version | Architecture | Disk Layout  | Extra  |
|-----|------------|---------|--------------|--------------|--------|
| 001 | Almalinux  | 8.4     | x86_64       |              |        |
| 002 | CentOS     | 8       | x86_64       |              |        |
| 003 | Rockylinux | 8.4     | x86_64       |              |        |
| 004 | Ubuntu     | 20.04   | x86_64       |              |        |
| 005 | Ubuntu     | 20.04   | x86_64       |              |        |
| 006 | Ubuntu     | 20.04   | x86_64       |              |        |
| 007 | Ubuntu     | 20.04   | x86_64       |              |        |

## Download

Images are downloadable at the following URLs:

* https://minio.services.osism.tech/openstack-ironic-images/ubuntu-20.04-amd64-efi.gz

## Files

* packer configuration: ubuntu-20.04-amd64.json
* preseed file: http/preseed.cfg
* post scripts: scripts/
  * sshd.sh
  * minimize.sh
* post scripts ubuntu: scripts/ubuntu/
  * update.sh
  * sudoers.sh
  * node.sh
  * cleanup.sh
* post scripts centos stream/almalinux/rockylinux: scripts/cenots-stream/
  * update.sh
  * sudoers.sh
  * node.sh
  * cleanup.sh
* provision scripts: scripts/provision
  * node.yml, called in node.sh
  * cleanup.yml, called in cleanup.yml
    * cleanup-Debian.yml
    * cleanup-RedHat.yml
  * growlvm.sh (dev)
  * distribution variables
    * RedHat.yml
    * Debian.yml
  * netplan configuration
    * 01-netcfg.yaml
* image.qcow2 will be in directory /dev/shm/
* packer binary: <https://www.packer.io/downloads>

## Create image

```bash
git clone ..
cd packer-ironic-images
```

* replace TODO in preseed file with password for user install and rename to e.g. preseed.cfg-example -> preseed.cfg

```bash
packer validate (-syntax-only) ubuntu-20.04-amd64-efi.json
packer build ubuntu-20.04-amd64-efi.json
```

### Create minimal image

```bash
packer validate (-syntax-only) ubuntu-20.04-amd64-efi-minimal.json
packer build ubuntu-20.04-amd64-efi-minimal.json
```

## Build with cirrus

<https://cirrus-ci.com/github/osism/openstack-ironic-images>

## Work in progress

* all *gpt* and *autoinstall* configurations and files are a work in progress
