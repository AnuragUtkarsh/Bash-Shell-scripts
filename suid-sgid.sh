#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/suid_sgid_audit.log"

os_info(){
	echo -e "========================================\nSUID / SGID AUDIT\n========================================" >> "$LOGFILE"
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo  "Date: $(date)" >> "$LOGFILE"
}

suid_info(){
	while read -r permission lcount owner group size month date year fname
	do
		echo "File: $fname"
		echo
		echo "Owner: $owner"
		echo
		echo "Group: $group"
		echo
		echo "Permission: $(stat -c %a $fname)"
	done< <(for i in $(find / -type f -perm -4000 2>/dev/null);do ls -l $i;done)
} >> "$LOGFILE"

sgid_info(){
	while read -r permission lcount owner group size month date year fname
	do
		echo "File: $fname"
		echo
		echo "Owner: $owner"
		echo
		echo "Group: $group"
		echo
		echo "Permission: $(stat -c %a $fname)"
	done< <(for i in $(find / -type f -perm -2000 2>/dev/null);do ls -l $i;done)
} >> "$LOGFILE"

os_info
suid_info
sgid_info
echo -e "========================================\nSECURITY SUMMARY\n========================================" >> "$LOGFILE"
echo "SUID Files: $(find / -type f -perm -4000 2>/dev/null|wc -l)" >> "$LOGFILE"
echo "SGID Files: $(find / -type f -perm -2000 2>/dev/null|wc -l)" >> "$LOGFILE"
echo "========================================" >> "$LOGFILE"


