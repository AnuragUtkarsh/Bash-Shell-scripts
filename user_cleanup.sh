#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT
LOGFILE=/tmp/user_cleanup.log

user_info(){
	echo -e "========================================\nUSER CLEANUP AUDIT\n========================================" >> "$LOGFILE"
	echo "Hostname: $hostname" >> "$LOGFILE"
	echo "Date: $date" >> "$LOGFILE"
	return 0
}

function user_clean {
	while IFS=: read -r username password uid gid info home_dir shell;
	do
                last_login=$(lastlog -u "$username")
		if [[ $uid -ge 1000 ]]
		then
			if echo "$last_login" | grep -q "Never logged in"
			then
				if [[ ! -f "$home_dir/.ssh/authorized_keys" ]]
				then
					echo "User: $username"
					echo "UID: $uid"
					echo "Home: $home_dir"
					echo "Last Login: "
					echo "$username has no ssh Key"
					echo "Status: CLEANUP Candiate"
		                else
			                echo "Status: Don't need cleanup"
				fi
			fi
		fi
	done < /etc/passwd >> "$LOGFILE"
	return 0
}

if user_clean
then
	echo "Cleanup successful" >> "$LOGFILE"
	exit 0
else
	echp "Cleanup Fail" >> "$LOGFILE"
	exit 1
fi
