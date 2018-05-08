#!/bin/bash
yum install xfsdump -y


pvcreate /dev/sdb
vgcreate vg_root
vgcreate vg_root /dev/sdb
lvcreate -n lv_root -l +100%FREE /dev/vg_root
mkfs.xfs /dev/vg_root/lv_root 
 
mount /dev/vg_root/lv_root /mnt
yum install xfsdump
xfsdump -f /tmp/root.dump /dev/VolGroup00/LogVol00
xfsrestore -f /tmp/root.dump /mnt/