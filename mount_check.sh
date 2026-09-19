#!/bin/bash

trap 'echo "Someone has pressed Ctrl+C";exit 1' INT

LOGFILE="/tmp/mount_check.sh"
mounts=()
mounted=0
not_mounted=0
read -p "Enter number of mount points to be checked: " count

for ((i=1; i<=count; i++))
do
	read -p "Enter Mount point name $i:" mount_point
	mounts+=("$mount_point")
done

for mount_point in "${mounts[@]}"
do
	if findmnt "$mount_point" &> /dev/null
	then
		echo "Mounted: $mount_point"
		findmnt -T "$mount_point" -o SOURCE,FSTYPE,TARGET >> "$LOGFILE"
		((mounted++))
	else
		echo "Not Mounted: $mount_point"
		((not_mounted++))
	fi
done

mount_report(){
	echo -e "========================================\nMOUNT CHECK REPORT\n========================================" >> "$LOGFILE"
	echo "Total Mount point: "${#mounts[@]}"" >> "$LOGFILE"
	echo "Mounted: "$mounted"" >> "$LOGFILE"
	echo "Not Mounted: "$not_mounted"" >> "$LOGFILE"
	echo "========================================"  >> "$LOGFILE"
	return 0
}

if mount_report
then
	echo "Report published successfully" >> "$LOGFILE"
else
	echo "Report Publishing failed" >> "$LOGFILE"
fi
