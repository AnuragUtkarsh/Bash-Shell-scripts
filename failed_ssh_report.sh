#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/failed-ssh.log"

os_report(){
	echo -e "========================================\nFAILED SSH LOGIN REPORT\n========================================" >> "$LOGFILE"
	echo "Hostname: "$(hostname)"" >> "$LOGFILE"
	echo "Authfile: "$logfile"" >> "$LOGFILE"
}

function parse_option {
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

ssh_failed(){
	failed_attempt=$(grep -i "authentication failure" "$logfile" | awk '{print $15}' | sort | uniq -c) >> "$LOGFILE"
	echo "Total Failed Attempts: "$failed_attempt"" >> "$LOGFILE"
	source_ip=$(grep -i "authentication failure" "$logfile" | awk '{print $14}' | sort | uniq -c) >> "$LOGFILE"
	echo "SOURCE IP SUMMARY: "$source_ip"" >> "$LOGFILE"
}
	
parse_option "$@"
os_report
ssh_failed



