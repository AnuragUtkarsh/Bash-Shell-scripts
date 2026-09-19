#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT
LOGFILE="/tmp/filethreshold.txt"
critical=0
warning=0
healthy=0
os_info(){
	echo -e "========================================\nFILESYSTEM ALERT REPORT\n========================================" >> "$LOGFILE"
	echo "HOSTNAME: $(hostname)" >> "$LOGFILE"
	echo "Date: $(date)" >> "$LOGFILE"
	echo "Author: Anurag Utkarsh" >> "$LOGFILE"
}

mount_check(){
	while IFS="" read -r filesystem size used avail usage mountpoint;
	do
		usage=$(echo "$usage" | tr -d "%")
		if [[ "$usage" -ge 90 ]]
		then
			echo "CRITICAL"
			((critical++))
		elif [[ "$usage" -ge 80 ]]
		then
			echo "WARNING"
			((warning++))
		else
			echo "HEALTHY"
			((healthy++))
		fi
	done < <(df -h | tail -n+2)
} >> "$LOGFILE"

os_info
mount_check
echo "Total Filesystem: "$(df -hT | tail -n+2 | wc -l)"" >> "$LOGFILE"
echo "Healthy: "$healthy"" >> "$LOGFILE"
echo "Warning: "$warning"" >> "$LOGFILE"
echo "CRITICAL: "$critical"" >> "$LOGFILE"
echo "========================================" >> "$LOGFILE"


