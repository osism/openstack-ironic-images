# openstack-ironic-images

## files

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

## create image

```bash
git clone ..
cd packer-ironic-images
change ssh pub key in node.sh
replace TODO in preseed file with password for user ubuntu and rename to e.g. preseed.cfg-example -> preseed.cfg
packer validate (-syntax-only) ubuntu-20.04-amd64.json
packer build ubuntu-20.04-amd64.json
```

### create minimal image

```bash
packer validate (-syntax-only) ubuntu-20.04-amd64-minimal.json
packer build ubuntu-20.04-amd64-minimal.json
```

## build with cirrus

<https://cirrus-ci.com/github/osism/openstack-ironic-images>

## Work in progress

All *gpt* and *autoinstall* configuration and files are work in progress
