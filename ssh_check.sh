#!/bin/bash

trap 'echo "Someone has pressed Ctrl+C";exit 1' INT

LOGFILE="/tmp/ssh_check.txt"

connected=0
failed=0

os_report(){
	echo -e "============\nSSH CHECKER\n==============" >> "$LOGFILE"
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Date: $(date)" >> "$LOGFILE"
}

parse_option(){
	while getopts "s:h" opt
	do
		case "$opt" in 
			s)
				read -a servers <<< "$OPTARG"
				;;
			h)
				#help
				;;
			*)
				#invalid option
				;;
		esac
	done
}
port_checker(){
	for server in "${servers[@]}"
	do
		if nc -z "$server" 22
		then
			echo "SSH Port is open for $server"
		else
			echo "SSH Port is not open for $server"
		fi
	done
} >> "$LOGFILE"

ssh_check(){
	for server in "${servers[@]}"
	do
		if ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$server" "exit"
		then
			echo "$server: SSH Connected"
			((connected++))
		else
			echo "$server: SSH Failed"
			((failed++))
		fi
	done
} >> "$LOGFILE"
os_report
parse_option "$@"
port_checker
ssh_check
echo "Total SSH Success: $connected" >> "$LOGFILE"
echo "Total SSH Failed: $failed" >> "$LOGFILE"
echo "Logs are saved at: $LOGFILE"
