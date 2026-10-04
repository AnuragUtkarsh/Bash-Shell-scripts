#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/filebackup.log"
echo "Choose an option"
echo "1) Backup"
echo "2) Restore"
echo "3) Exit"
read -p "Choose an option: " opt
echo -e "========================================\nFILE BACKUP / RESTORE\n========================================" >> "$LOGFILE"

backup_option(){
	echo -e "========================================\nBACKUP OPERATION\n========================================"
	src_file="$1"
	bkp_dir="$2"
	echo "Source: $src_file"
	echo "Destination: $bkp_dir"
	# creating tar backup
	if [[ ! -e "$src_file" ]]
	then
		echo "Source file not exist"
		return 1
	else
		fname=$(basename $src_file)
		echo "Creating tar backup"
		if tar -czvf "${bkp_dir}/${fname}"_$(date +%Y%m%d_%H%M%S) "$src_file"
		then
			echo "Backup has been created successfully"
			echo "Status: Success"
			echo "Backup Size: $(ls -l "${bkp_dir}/${fname}"_$(date +%Y%m%d_%H%M%S) | awk '{print $5}')"
		else
			echo "backup has failed"
			echo "Status: failed"
			return 1
		fi
	fi
} >> "$LOGFILE"

restore_option(){
	echo -e "========================================\nRESTORE OPERATION\n========================================"
	bkp_file="$1"
	res_dest="$2"
	echo "Backup File: $bkp_file"
	echo "Restore To: $res_dest"

	if [[ ! -e "$bkp_file" ]]
	then
		echo "File not exist"
		return 1
	else
		echo "WARNING: Existing files may be overwritten."
		read -p "Do you want to continue? (yes/no): " ans
		if [[ "$ans" == "yes" || "$ans" == "Yes" ]]
		then
			echo "Restoring"
			cp -avp "$bkp_file" "$res_dest"
			if [[ -e "$res_dest" ]]
			then
				echo "Restore completed successfully"
			else
				echo "Restoration has failed"
			fi
		else
			echo "Restoring abort"
			return 1
		fi
	fi
	#validation
	if [[ -e "$bkp_file" ]]
	then
		if [[ -e "$res_dest" ]]
		then
			echo "Backup Dir: EXISTS"
			echo "Restore Dir : EXISTS"
			echo "Status      : SUCCESS"
		else
			echo "destination doesn't exist"
		fi
	else
		echo "Validation failed"
	fi
}

if [[ $# -ne 2 ]]
then
	echo "Usage: $0 <src> <dest>"
	exit 1
fi

case "$opt" in
	1)
		backup_option "$1" "$2"
		;;
	2)
		restore_option "$1" "$2"
		;;
	3)
		exit 1
		;;
	*)
		echo "Invalid option"
		;;
esac
