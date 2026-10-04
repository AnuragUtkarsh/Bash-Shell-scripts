#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/service_recovery.log"

service_heal(){
	echo -e "==========\nServiceHeal\n========="
	svc="$1"
	#check the service existence
	if ! systemctl cat "$svc" &>/dev/null
	then
		echo "Service doesn't exist"
		return 1
	fi
	#check service status
	act=$(systemctl is-active "$svc")
	enab=$(systemctl is-enabled "$svc")

	if [[ "$act" == "active" ]]
	then
		if [[ "$enab" == "enabled" ]]
		then
			echo "Service: $svc"
			echo "Status: ACTIVE"
			echo "Status: ENABLED"
			echo "No Recovery Required"
		else
			echo "Service is disabled"
		fi
	else
		echo "Recent logs:"
                journalctl -u "$svc" -n 10 --no-pager
		echo "Service is not running"
		read -p "Do You want to restart it(Yes/No): " ans
		if [[ "$ans" == "yes" || "$ans" == "Yes" ]]
		then
			echo "Starting the service"
			systemctl restart "$svc"
			act_after=$(systemctl is-active "$svc")
			#check if service running after restart
			if [[ "$act_after" == "active" ]]
			then
				echo "Service restarted successfully"
			else
				echo "Service restart failed"
			fi
		else
			echo "Abort restart"
			return 1
		fi
	fi
} >> "$LOGFILE"
#valid argument count
if [[ $# -ne 1 ]]
then
	echo "Usage: $0 <service"
	exit 1
fi

service_heal "$1"
       	
