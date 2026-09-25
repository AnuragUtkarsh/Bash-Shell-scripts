#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/dnsresult.txt"
resolve=0
unresolve=0
os_report(){
	echo -e "==========\nDNS Checker\n==========" >> "$LOGFILE"
	echo "HOSTNAME: $(hostname)" >> "$LOGFILE"
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
				#invalid request
				;;
		esac
	done
}

dns_resolver(){
	for server in ${servers[@]}
	do
		if getent hosts "$server"
		then
			echo "Resolved: $server"
			((resolve++))
		else
			echo "Unresolved: $server"
			((unresolve++))
		fi
	done
} >> "$LOGFILE"

parse_option "$@"
os_report
dns_resolver
echo "Total Resolved: $resolve" >> "$LOGFILE"
echo "Total Unresolved: $unresolve" >> "$LOGFILE"
#./dns_check.sh -s "app01 app03 google.com"
