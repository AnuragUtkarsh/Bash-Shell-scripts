#!/bin/bash

LOGFILE=/tmp/memory_report.log
UMemory=$(free -m | awk 'NR==2{print $3}')
AMemory=$(free -m | awk 'NR==2{print $7}')
TMemory=$(free -m | awk 'NR==2{print $2}')
UsedPercentage=$(( UMemory * 100 / TMemory ))
FreePercentage=$(( (TMemory-UMemory) *100 /TMemory))
function memory_check {
	echo "========== MEMORY REPORT ==========" >> "$LOGFILE"
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Date: $(date)" >> "$LOGFILE"
	echo "Total Memory: $TMemory" >> "$LOGFILE"
        echo "Used Memory: $UMemory" >> "$LOGFILE"	
	echo "Available Memory: $AMemory" >> "$LOGFILE"
	echo "Used Percentage: $UsedPercentage" >> "$LOGFILE"
	echo "Free Percentage: $FreePercentage" >> "$LOGFILE"
	return 0
}

trap 'echo "Someone has pressed CTRL+C";exit 1' INT
memory_check
echo "===================================" >> "$LOGFILE"

if [[ $? -eq 0 ]]
then
	echo "Successful"
	exit 0
else
	echo "fail"
	exit 1
fi
