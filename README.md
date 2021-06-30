# openstack-ironic-images

This repository is used to manage build recipes for creating images for use on baremetal systems.

## Download

Images are downloadable at the following URL:

https://images.osism.io/minio/openstack-ironic-images/

## Files

* packer configuration: ubuntu-20.04-amd64.json
* preseed file: http/preseed.cfg
* post scripts: scripts/
  * update.sh
  * sshd.sh
  * sudoers.sh
  * node.sh
  * cleanup.sh
  * minimize.sh
* provision scripts: scripts/provision
  * node.yml, called in node.sh
  * cleanup.yml, called in cleanup.yml
  * growlvm.sh
* image.qcow2 will be in directory builds/
* packer binary: <https://www.packer.io/downloads>

## Create image

```bash
git clone ..
cd packer-ironic-images
```

* change SSH public key in node.sh
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
