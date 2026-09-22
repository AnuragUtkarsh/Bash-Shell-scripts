#!/bin/bash

trap 'echo "Someone has presses CTRL+C";exit 1' INT

LOGFILE="/tmp/logrotate.txt"

os_report(){
	echo -e "========================================\nLOG ROTATION REPORT\n========================================" >> "$LOGFILE"
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Directory: $dir" >> "$LOGFILE"
}

log_rotate(){
	read -p "Enter how many days old log you want to rotate: " rottime
	while read -r line
	do
		echo "$line"
	done< <(find "$dir" -type f -mtime +"$rottime")

        totsize=$(find "$dir" -type f -mtime +"$rottime" -exec ls -l {} + | awk '{sum+=$5} END {printf "%.2f M\n", sum/1024/1024}')
	totnum=$(find "$dir" -type f -mtime +"$rottime" -ls | wc -l)
	echo "Total size to be deleted: $totsize"
	read -p "Do you Want to delete these files(yes/no): " ans

	if [[ "$ans" == yes ]]
	then
		while read -r line
		do
			gzip -v "$line"
		done< <(find "$dir" -type f -mtime +"$rottime" -ls)
		find "$dir" -type f -mtime +"$rottime" -delete
		echo "files has been deleted"
	else
		echo "Aborting delete operation"
	fi
} >> "$LOGFILE"

parse_option(){
	while getopts "a:b" opt
	do
		case "$opt" in
			a)
				if [[ -d "$OPTARG" ]]
				then
					dir="$OPTARG"
				fi
				;;
			b)
				#help
				;;
			*)
				#invalid option
				;;
		esac
	done
}

parse_option "$@"
os_report
log_rotate
