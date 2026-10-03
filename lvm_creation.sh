#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT
LOGFILE="/tmp/createlv.log"

read -p "Enter the disk on which u want to create mount point: " dsk
read -p "Enter the VG name: " vg
read -p "Enter the LV name: " lv
read -p "Enter LV Size in (GB): " lsize
read -p "Enter the file system type(xfs/ext4): " fstype
read -p "Enter the mount point name: " mpt

lvm_creation(){
	echo -e "========================================\nLVM CREATE AUTOMATION\n========================================" >> "$LOGFILE"
	if [[ ! -b /dev/"$dsk" ]]
	then
		echo "Invalid block disk"
		exit 1
	fi
	echo "creating pv"
	pvcreate /dev/"$dsk"
	
	if vgs "$vg" >/dev/null 2>&1
	then
		echo "vg exist"
	else
		vgcreate "$vg" /dev/"$dsk"
	fi
	
	if lvdisplay "/dev/$vg/$lv" >/dev/null 2>&1
	then
		echo "lv exist"
	else
		lvcreate -L "${lsize}G" -n "$lv" "$vg"
         	mkfs -t "$fstype" /dev/"$vg"/"$lv"
	fi


	#creating mount point
	if [[ -d "$mpt" ]]
	then
		echo "mount point exist"
	else
		mkdir -p "$mpt"
	fi

	#mounting the mount point
	if findmnt "$mpt" &>/dev/null
	then
	        echo "Already mounted"
	else
		mount "/dev/$vg/$lv" "$mpt"
	fi

	#verify whether mounted or not
	if findmnt "$mpt" &>/dev/null
	then
		echo "successfully mounted: $mpt"
		if grep -qE "[[:space:]]$mpt[[:space:]]" /etc/fstab
                then
		    	echo "fstab entry already exists"
		else
		    	uuid=$(blkid -s UUID -o value "/dev/$vg/$lv")
		    	echo "UUID=$uuid $mpt $fstype defaults 0 0" >> /etc/fstab
			mount -av
		fi
	fi
	echo -e "========================================\nFINAL STATUS\n========================================" >> "$LOGFILE"
	if findmnt "$mpt" &>/dev/null
	then
	        echo "LVM successful"
	else
		echo "LVM Fail"
		return 1
	fi
} >> "$LOGFILE"	
lvm_creation
