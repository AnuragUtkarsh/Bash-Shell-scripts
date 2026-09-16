#!/bin/bash

LOGFILE=/tmp/logs.txt

function health {
	echo "$(hostname)" >> $LOGFILE
	echo "$(date)">> $LOGFILE
	echo "$(uname -a)" >> $LOGFILE
	echo "$(cat /etc/os-release)" >> $LOGFILE
	echo "$(uptime)" >> $LOGFILE
	echo "$(nproc)" >> $LOGFILE
	echo "$(free -gh)" >> $LOGFILE
	echo "$(df -h)" >> $LOGFILE
	echo "$(hostname -I)" >> $LOGFILE
}

echo "HEALTH CHECK Started" >> $LOGFILE
trap 'echo "Someone has pressed Ctrl+C";exit 1' INT

health

if [[ $? -eq 0 ]]
then
	echo "Health Check is successful"
else
	echo "Health Check is failed"
fi
