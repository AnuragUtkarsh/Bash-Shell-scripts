#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/inode.log"
healthy=0
warning=0
critical=0

inode_usage(){
	if [[ $# -eq 0 ]]
	then
		input=$(df -ih | awk 'NR>1 {print}')
	else
		input=$(df -ih "$1" | awk 'NR>1 {print}')
	fi
	while read -r fs inode iused ifree iusepercent mpt
	do
		usage=$(echo "$iusepercent" | tr -d "%")
		if [[ "$usage" -gt 90 ]]
		then
			echo "Inode usage critical"
			((critical++))
		elif [[ "$usage" -gt 75 && "$usage" -lt 90 ]]
		then
			echo "Inode usage high"
			((warning++))
		else
			echo "Inode usage under Threshold"
			((healthy++))
		fi
	done<<< "$input"
} >> "$LOGFILE"
if [[ $# -eq 0 ]]
then
	echo "Checking for all the file system" >> "$LOGFILE"
	inode_usage
else
	echo "Checking for supplied arguement" >> "$LOGFILE"
	for mpt in "$@"
	do
		echo "Checking: $mpt" >> "$LOGFILE"
		if findmnt "$mpt" &>/dev/null
		then
			inode_usage "$mpt"
		else
			echo "$mpt: mount point not exist"
		fi
	done
fi
echo "Healthy file system is: $healthy" >> "$LOGFILE"
echo "Warning file system is: $warning" >> "$LOGFILE"
echo "Critical file system is: $critical" >> "$LOGFILE"
