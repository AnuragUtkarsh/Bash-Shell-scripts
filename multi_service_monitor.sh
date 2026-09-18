#!/bin/bash

trap 'echo "Someone has pressed Ctrl+C";exit 1' INT

LOGFILE=/tmp/multi_service.txt

services=("sshd" "firewalld" "chronyd" "rsyslog")
healthy=0
unhealthy=0
unknown=0

service_check(){
	svc="$1"
	if systemctl cat "$svc" &>/dev/null
	then
		status=$(systemctl is-active "$svc")
		boot_status=$(systemctl is-enabled "$svc")
		if [[ "$status" == "active" ]]
		then
			echo "Service is Healthy"
			((healthy++))
		elif [[ "$status" == "inactive" ]] || [[ "$status" == "failed" ]]
		then
			echo "Service is Unhealthy"
			((unhealthy++))
		else
			echo "Service status is unknown"
			((unknown++))
		fi
	else
		echo "Service doesn't exist"
		((unknown++))
	fi
	return 0
} >> "$LOGFILE"

{
	for svc in "${services[@]}"
	do
		service_check "$svc"
	done
} >> "$LOGFILE"

echo -e "========================================\nSUMMARY\n========================================" >> "$LOGFILE"
echo "Total Service: "${#services[@]}"" >> "$LOGFILE"
echo "Healthy Service: "$healthy"" >> "$LOGFILE"
echo "Unhealthy Service: "$unhealthy"" >> "$LOGFILE"
echo "Unknown Service: "$unknown"" >> "$LOGFILE"
echo "========================================" >> "$LOGFILE"
