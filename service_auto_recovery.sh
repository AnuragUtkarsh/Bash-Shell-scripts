#!/bin/bash

LOGFILE="/tmp/service_auto_recovery.log"

trap 'echo "Someone has pressed Ctrl+C";exit 1' INT

services=("sshd" "chronyd" "rsyslog" "firewalld")
healthy=0
recovered=0
failed=0
unknown=0

service_status(){
	svc="$1"
	if systemctl cat "$svc" &>/dev/null
	then
		status=$(systemctl is-active "$svc")
		boot_enabled=$(systemctl is-enabled "$svc")
		if [[ "$status" == "active" ]]
		then
			echo "Before: Active"
			echo "Action: No Action"
			echo "Result: HEALTHY"
			((healthy++))
		elif [[ "$status" == "inactive" ]] || [[ "$status" == "failed" ]]
		then
			echo "Attempting Restart"
			attempt=1
			while [[ $attempt -le 2 ]]
			do
				systemctl restart "$svc"
			        after_status=$(systemctl is-active "$svc")
				if [[ "$after_status" == "active" ]]
				then
					echo "Recover successful on attempt: "$attempt""
					break
				else
					echo "Recovery attempt failed $attempt"
				fi
				((attempt++))
			done
			if [[ "$after_status" == "active" ]]
			then
				echo "After: active"
				echo "Result: HEALTHY"
				((recovered++))
			else
				echo "After: Failed"
				echo "UNHEALTHY"
				((failed++))

			fi
		else
			echo "Service: Unknown"
			((unknown++))
		fi
	else
		echo "Service doesn't exist"
		((unknown++))
	fi
} >> "$LOGFILE"

for svc in "${services[@]}"
do
	service_status "$svc"
done
