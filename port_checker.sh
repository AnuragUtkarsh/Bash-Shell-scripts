#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT
LOGFILE="/tmp/port_check.txt"
open=0
closed=0
os_report(){
	echo -e "============\nPort Checker\n===========" >> "$LOGFILE"
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Date: $(date)" >> "$LOGFILE"
}

parse_option(){
	while getopts "s:p:h" opt
	do
		case "$opt" in
			s)
				read -a servers <<< "$OPTARG"
				;;
			p)
				read -a ports <<< "$OPTARG"
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

port_check(){
	for server in "${servers[@]}"
	do
		for port in "${ports[@]}"
		do
			if nc -zv -w2 "$server" "$port"
			then
				echo "$server connecting to $port"
				((open++))
			else
				echo "Connectivity not exist over $port for $server"
				((closed++))
			fi
			
		done
	done
} >> "$LOGFILE"

parse_option "$@"
if [[ ${#servers[@]} -eq 0 ]]
then
    echo "No servers provided" >> "$LOGFILE"
    exit 1
fi
if [[ ${#ports[@]} -eq 0 ]]
then
    echo "No ports provided" >> "$LOGFILE"
    exit 1
fi
os_report
echo "Total open Port: $open" >> "$LOGFILE"
echo "Total Closed Port: $closed" >> "$LOGFILE"
port_check
# ./port_checker.sh -s "192.168.198.200 192.168.198.201 192.168.198.202" -p "22 80 443"
