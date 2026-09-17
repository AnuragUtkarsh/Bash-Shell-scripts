#!/bin/bash

LOGFILE=/tmp/password_expiry.log

os_report(){
	echo -e "========================================\nPASSWORD EXPIRY REPORT\n========================================" >>  "$LOGFILE"
	echo "Hostname: $(hostname)" >>  "$LOGFILE"
	echo "Date: $(date)" >> "$LOGFILE"
	return 0
}

expiry_info(){
	while IFS=: read -r  username password last_change min_days max_days warn_days inactive_days expire_date reserved;
	do
		echo "Username: $username"
		echo "Password: $password"
		echo "Last Change: $last_change"
		echo "Expires: $expire_date"
		echo "Warning: $warn_days"
		echo "Inactive: $inactive_days"
	done < /etc/shadow >> "$LOGFILE"
	return 0
}


if os_report && expiry_info 
then
	echo "Check Successful" >> "$LOGFILE"
	exit 0
else
	echo "Check unsuccessful" >> "$LOGFILE"
	exit 1
fi
