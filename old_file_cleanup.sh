#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/cleanup_old.txt"

read -p "Enter the Directory which you want to cleanup: " dir
read -p "Enter the number of days of which you wanted to delete logs: " dday

old_file(){
	if [[ -d "$dir" ]]
	then
		echo "Old Files: "
		find "$dir" -type f -mtime +"$dday" -ls
		oldfile=$(find "$dir" -type f -mtime +"$dday" | wc -l)
		size=$(find "$dir" -type f -mtime +"$dday" -ls | awk '{sum+=$7} END {printf "Total Size: %.2f KB\n",sum/1024}')
		read -p "Do you want to delete these files? (yes/no): " answer
		if [[ "$answer" == "yes" ]]
		then
			find "$dir" -type f -mtime +"$dday" -delete
		else
			echo "Aborting Delete Operation"
		fi
	else
		echo "Directory don't exist"
		exit 1
	fi
} >> "$LOGFILE"

old_file
echo -e "========================================\nOLD FILE CLEANUP REPORT\n========================================" >> "$LOGFILE"
echo "Total Old files: "$oldfile"" >> "$LOGFILE"
echo ""$size"">> "$LOGFILE" 
