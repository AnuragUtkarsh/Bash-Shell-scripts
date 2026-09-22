#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/loganalyse.txt"

os_info(){
	echo -e "========================================\nAUTHENTICATION LOG ANALYZER\n========================================" >> "$LOGFILE"
	echo "HOSTNAME: $(hostname)" >> "$LOGFILE"
	echo "Log File: "$logfile"" >> "$LOGFILE"
}
parse_option(){
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
				#invalid Option
				;;
		esac
	done
}

auth_analyzer(){
	echo -e "========================================\nAUTHENTICATION SUMMARY\n========================================" >> "$LOGFILE"
	echo "Successful Login: $(grep -c "Accepted" "$logfile")" >> "$LOGFILE"
	echo "Failed Login: $(grep -c "Failed password" "$logfile")" >> "$LOGFILE"
	echo "Failed Source IPs: $(grep  "Failed password" "$logfile" | awk '{print $12}' | sort |uniq -c)" >> "$LOGFILE"
	echo "Top Accepted: $(grep  "Accepted" "$logfile" | awk '{print $9}' | sort | uniq -c)" >> "$LOGFILE"
	echo "========================================" >> "$LOGFILE"
}

parse_option "$@"
os_info
auth_analyzer
