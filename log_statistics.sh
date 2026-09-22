#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/logstat.txt"

os_report(){
	echo -e "========================================\nLOG STATISTICS REPORT\n========================================" >> "$LOGFILE"
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Logfile: $logfile" >> "$LOGFILE"
}

function logstatistics {
	total_line=$(wc -l < "$logfile")
	echo "Total line is: $total_line"
	while read -r user 
	do
		echo "Unique user: $user"
	done < <(cat "$logfile" |grep -i user| awk '{print $11}'| sort | uniq)

	while read -r ip
	do
		echo "Unique IP: $ip"
	done < <(cat "$logfile" | grep -i from |awk '{print $11}'| sort | uniq)

	patterns=( "Accepted" "failed" "error" "warning" )
	for pattern in "${patterns[@]}"
	do
		count=$(grep -ic "$pattern" "$logfile")
		echo "$pattern: $count"
	done
} >> "$LOGFILE"

parser_option(){
	while getopts "a:b" opt
	do
		case "$opt" in
			a)
				logfile="$OPTARG"
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
parser_option "$@"
os_report
logstatistics
