#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/service_report.log"

services=("sshd" "chronyd" "rsyslog" "firewalld")

actv=0
inactiv=0
fail=0
enabl=0
disab=0
unknown=0

service_check(){
	svc="$1"
	if systemctl cat "$svc" &>/dev/null
	then
		status=$(systemctl is-active "$svc")
		boot_enabled=$(systemctl is-enabled "$svc")
		if [[ "$status" == "active" ]]
		then
			echo "Status: active"
			((actv++))
			if [[ "$boot_enabled" == "enabled" ]]
			then
				echo "Boot Status: Enabled"
				((enabl++))
			else
				echo "Boot Status: Disabled"
				((disab++))
			fi
		echo "Health: HEALTHY"
		elif [[ "$status" == "inactive" ]]
		then
			echo "Status: Inactive"
			((inactiv++))
			if [[ "$boot_enabled" == "enabled" ]]
                        then
                                echo "Boot Status: Enabled"
                                ((enabl++))
                        else
                                echo "Boot Status: Disabled"
                                ((disab++))
                        fi
		echo "Health: UNHEALTHY"
		elif [[ "$status" == "failed" ]]
		then
			echo "Status: failed"
			((fail++))
                        if [[ "$boot_enabled" == "enabled" ]]
                        then
                                echo "Boot Status: Enabled"
                                ((enabl++))
                        else
                                echo "Boot Status: Disabled"
                                ((disab++))
                        fi
		echo "Health: UNHEALTHY"
		fi
	else
		echo "Service Not exist"
		((unknown++))
	fi
} >> "$LOGFILE"


os_report(){
	echo -e "========================================\nSERVICE REPORT\n========================================" >> "$LOGFILE"
	echo "Hostname: $(hostname)"  >> "$LOGFILE"
	echo "Date: $(date)" >> "$LOGFILE"
} >> "$LOGFILE"
os_report
for svc in "${services[@]}"
do
	service_check "$svc"

done
