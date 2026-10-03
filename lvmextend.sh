#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/lvextend.log"

read -p "Enter the mount name which you want to extend(/abc): " mpt
read -p "Enter the extended size of the lv: " nsize


lvm_extension(){
	# find the lv of the mount point.
	lv=$(findmnt "$mpt" | awk 'NR>1 {print $2}')
	osize=$(df -hT "$mpt" | awk 'NR>1 {print $3}')
	old_bytes=$(numfmt --from=iec "$osize")
        new_bytes=$(numfmt --from=iec "${nsize}G")
	if [[ -z "$lv" ]]
	then
		echo "Unable to find mount point"
		exit 1
	fi
	if [[ "$new_bytes" -gt "$old_bytes" ]]
	then
		echo "extending the lv"
		echo "DEBUG nsize=[$nsize]"
                echo "DEBUG target=[${nsize}G]"
                echo "DEBUG lv=[$lv]"
		lvextend -L "$nsize"G "$lv" -r
	else
		echo "Size is lesser than older one"
		exit 1
	fi
} >> "$LOGFILE"

lvm_extension




