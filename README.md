# openstack-ironic-images

## stress-ng

```
qemu-img convert -O raw osism-stress-ng-image.qcow2 osism-stress-ng-image.raw
sudo dd if=osism-stress-ng-image.raw of=/dev/sdb bs=1M
```
