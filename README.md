# openstack-ironic-images

## burnin

The image is used to read out some information about a system and perform
rudimentary memory and CPU tests. The results are saved under /opt.

Once all tests have been completed, the system is shut down.

```
$ sudo dd if=osism-burnin-image.raw of=/dev/sdb bs=8M status=progress
```

```
$ sudo parted /dev/sdb print
Warning: Not all of the space available to /dev/sdb appears to be used, you can fix the GPT to use all
of the space (an extra 112797696 blocks) or continue with the current setting?
Fix/Ignore? ignore
Model:  USB  SanDisk 3.2Gen1 (scsi)
Disk /dev/sdb: 61.5GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags:

Number  Start   End     Size    File system  Name  Flags
 1      1049kB  578MB   577MB   fat32        ESP   boot, esp
 2      578MB   586MB   8389kB               BSP   bios_grub
 3      586MB   3771MB  3185MB  ext4         root
```
