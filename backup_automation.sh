#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/backup.log"

read -p "Enter the Diretory to be backup: " bkpdir
read -p "Enter the Destination Directory: " destdir

backup_take(){
	if [[ -d "$bkpdir" ]]
	then
		if [[ -d "$destdir" ]]
		then
			echo "taking backup"
			if rsync -avzh "$bkpdir" "$destdir"
			then
				echo "Backup Status: SUCCESS"
			else
				echo "Backup Status: FAILED"
			fi
		else
			echo "Destination Directory doesn't exist"
			exit 1
		fi
	else
		echo "Backup Diectory Given Doesn't exist"
		exit 1
	fi
} >> "$LOGFILE"

os_info(){
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Date: $(date)">> "$LOGFILE"
	echo "Source: "$bkpdir"" >> "$LOGFILE"
	echo "Destination: "$destdir"" >> "$LOGFILE"
}


echo -e "========================================\nBACKUP REPORT\n========================================" >> "$LOGFILE"
os_info
backup_take
echo "========================================" >> "$LOGFILE"

