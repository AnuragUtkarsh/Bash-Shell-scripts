#!/bin/bash

LOGFILE=/tmp/user_audit.log
trap 'echo "Someone has pressed Ctrl+C"; exit 1' INT
system_count=0
normal_count=0
root_count=0
function os_report {
	echo "Collecting system Information" >> "$LOGFILE"
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Date & Time: $(date)" >> "$LOGFILE"
	return 0
}

Total_user=$(wc -l < /etc/passwd )


function user_info {
	while IFS=: read -r username password uid gid info home_dir shell;
	do
		if [[ "$uid" -le 999 && "$uid" -ne 0 ]]
		then
			echo " It is a system user $username"
			((system_count++))
		elif [[ "$uid" -eq 0 ]]
		then
			echo " It is root user $username"
			((root_count++))
		else
			echo "It is normal user $username"
			((normal_count++))
		fi
	done < /etc/passwd >> "$LOGFILE"
	echo "System Users : $system_count" >> "$LOGFILE"
        echo "Normal Users : $normal_count" >> "$LOGFILE"
        echo "Root Users   : $root_count" >> "$LOGFILE"
	return 0

}


loggeduser=$(who)

user_shell(){
	while IFS=: read -r username password uid gid info home_dir shell;
	do
		if [[ "$shell" == /bin/bash || "$shell" == /bin/sh ]]
		then
			echo "valid shell"
		elif [[ "$shell" == /sbin/nologin ]]
		then
			echo "No Login shell"
		else
			echo "Invalid shell"
		fi
	done < /etc/passwd >> "$LOGFILE"
	return 0
}


home_dir(){
	while IFS=: read -r username password uid gid info home_dir shell;
        do
		if [[ -d "$home_dir" ]]
		then
			echo "User [$username]: home directory exists ($home_dir)"
		else
			echo "User [$username]: home directory DOES NOT exist ($home_dir)"
		fi
	done < /etc/passwd >> "$LOGFILE"
	return 0
}

echo "Total user is: "$Total_user"" >> "$LOGFILE"
echo "Current Logged in user: "$loggeduser"" >> "$LOGFILE"

if os_report && user_info && user_shell && home_dir
then
	echo "User Audit completed successfully" >> "$LOGFILE"
	exit 0
else
	echo "User Audit Failed" >> "$LOGFILE"
	exit 1
fi
