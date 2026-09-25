#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/network_report.txt"

network_report(){
	echo -e "========================================\nNETWORK REPORT\n========================================" >> "$LOGFILE"
	for i in $(nmcli device status | awk 'NR>1 {print $1}')
	do
		echo "Interfaces avaliable are: $i"
	done
	echo "Ip Address in server: $(hostname -I)"
	echo "Default Route: $(ip route)"
	echo "DNS Configuration: $(cat /etc/resolv.conf)"
	while read -r protocol recvq sendq local_address foreign_address state process
	do
		echo "Protocol: $protocol"
		echo "State: $state"
	done < <(netstat -ntlpua | grep -i listen)
	if ping -c2 -W2 $(ip route | awk 'NR==1{print $3}') &>/dev/null
	then
		echo "Network Connectivity: Pass"
	else
		echo "Network Connectivity: failed"
	fi
	echo -e "========================================\nNETWORK SUMMARY\n========================================" >> "$LOGFILE"

} >> "$LOGFILE"

network_report





