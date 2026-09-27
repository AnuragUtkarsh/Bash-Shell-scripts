#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/worldreadwrite.log"

os_info(){
	echo -e "========================================\nWORLD-WRITABLE FILE AUDIT\n========================================" >> "$LOGFILE"
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Date: $(date)" >> "$LOGFILE"
}

writable_file(){
	echo "--- WORLD-WRITABLE FILES ---"
	while read -r owner group permission fname
	do
		echo "Filename: $fname"
		echo
		echo "Owner: $owner"
		echo
		echo "Group: $group"
		echo
		echo "Permission: $permission"
		echo
	done< <(for i in $(find / -type f -perm -0002 2>/dev/null);do stat -c "%U %G %a %n" $i;done 2>/dev/null)
	echo "Total World-Writable Files: $(find / -type f -perm -0002 2>/dev/null|wc -l)"
}>> "$LOGFILE"

writable_directory(){
	echo "--- WORLD-WRITABLE DIRECTORIES ---"
	while read -r owner group permission dname
	do
	       echo "Directoryname: $dname"
	       echo
	       echo "Owner: $owner"
	       echo
	       echo "Group: $group"
	       echo
	       echo "Permission: $permission"
	       echo
       done< <(for i in $(find / -type d -perm -0002 2>/dev/null);do stat -c "%U %G %a %n" $i;done 2>/dev/null)
       echo "Total World-Writable Directories: $(find / -type d -perm -0002 2>/dev/null|wc -l)"
} >> "$LOGFILE"

os_info
writable_file
writable_directory
