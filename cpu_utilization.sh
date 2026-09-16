#!/bin/bash

LOGFILE=/tmp/cpu_report.log

function cpu_health {
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Date: $(date)" >> "$LOGFILE"
	echo "Kernel: $(uname -r)" >> "$LOGFILE"
	echo "CPU Model: $(lscpu |grep -w "^Model:")" >> "$LOGFILE"
	echo "CPU Architecture: $(lscpu | grep -i Architecture)" >> "$LOGFILE"
	echo "CPU Cores: $(lscpu | grep -i "Core(s) per socket")" >> "$LOGFILE"
	echo "CPU Threads: $(lscpu | grep -i "Thread(s) per core:")" >> "$LOGFILE"
	echo "CPU Sockets: $(lscpu | grep -i "Socket(s):")" >> "$LOGFILE"
	echo "1 Minute: $(w | awk 'NR==1{print $8}')" >> "$LOGFILE"
	echo "5 Minute: $(w | awk 'NR==1{print $9}')" >> "$LOGFILE"
	echo "15 Minute: $(w | awk 'NR==1{print $8}')" >> "$LOGFILE"
}

echo "===== CPU REPORT =====" >> "$LOGFILE"

trap 'echo "Someone has CTRL+C";exit 1' INT
cpu_health

if [[ $? -eq 0 ]]
then
	echo "CPU check successful"
	exit 0
else
	echo "CPU check failed"
	exit 1
fi





