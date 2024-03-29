#!/usr/bin/bash
#This scrips finds new disks (disks without partitions nor labels), puts them under LVM control, creates an xfs filesystem in them
#creates one directory under /mnt for each disk, adds an entry to the /etc/fstab for each disk and mounts the disk.
#Also, writes a data/time stamped file with the new added raw disks devices /dev/sdxx to keep track of when disks were added.

rm -f devices
rm -f newdevice
ls /dev | grep sd | sed -e "s/vg_[^ ]*//ig" | sed '/^[[:space:]]*$/d' > devices
for device in `cat devices`; do
    dev=`fdisk /dev/$device -l | grep -i 'Disk label type:'`
    label=`lsblk -f /dev/$device | awk 'NR>1{ print $3 }'`
    if ([[ $dev == "" ]] && [[ $label == "" ]]) ; then
     {
       echo $device >> newdevice
       pvcreate /dev/$device --dataalignment 256
       vgcreate vg_$device /dev/$device
       lvcreate --type thin-pool -l 100%FREE -n lv_vg_$device vg_$device --chunksize 256KiB --poolmetadatasize 16GiB
       mkfs.xfs /dev/mapper/vg_$device-lv_vg_$device -i size=512
       directory=`echo $device | cut -c 3-`
       mkdir /mnt/brick$directory
       echo "/dev/mapper/vg_$device-lv_vg_$device       /mnt/brick$directory    xfs     defaults        0 0" >> /etc/fstab
     }
    fi
done
mount -a
cat newdevice
echo "devices added successfully"
mv newdevice DiskExpansions$(date "+%m.%d.%y-%H.%M.%S").txt
rm -f newdevice
rm -f devices
