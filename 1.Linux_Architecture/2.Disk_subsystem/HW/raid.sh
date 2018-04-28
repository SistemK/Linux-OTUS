#!/bin/bash

echo "Start creating RAID"
echo " "

mdadm --create /dev/md0 -l 6 -n 5 /dev/sd{c,d,e,f,g}

mdadm -D /dev/md0
if [ $? == 0 ]
then
    echo "RIAD created succesfuly"
else
    echo "RAID was not created"
    break
fi


# Creating partitions
for part in {1..5}
do
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk /dev/md0
  n


  +100M

  w
  Y
EOF
done

mkfs.ext4 /dev/md0p1
mkfs.ext4 /dev/md0p2
mkfs.ext4 /dev/md0p3
mkfs.ext4 /dev/md0p4
mkfs.ext4 /dev/md0p5

mkdir /u0{1,2,3,4,5}
echo -e `sudo blkid | grep md0 | awk '/md0p1/ {print $2}'` /u01 ext4 defaults 0 0 >> /etc/fstab
echo -e `sudo blkid | grep md0 | awk '/md0p2/ {print $2}'` /u02 ext4 defaults 0 0 >> /etc/fstab
echo -e `sudo blkid | grep md0 | awk '/md0p3/ {print $2}'` /u03 ext4 defaults 0 0 >> /etc/fstab
echo -e `sudo blkid | grep md0 | awk '/md0p4/ {print $2}'` /u04 ext4 defaults 0 0 >> /etc/fstab
echo -e `sudo blkid | grep md0 | awk '/md0p5/ {print $2}'` /u05 ext4 defaults 0 0 >> /etc/fstab

mount -a

echo " "
echo "Done creating RAID"