#!/bin/bash
trap 'echo "Someone has pressed CTRL+C";exit 1;' INT
LOGFILE=/tmp/ssh_key_audit.log

function os_report {
	echo -e "========================================\nSSH KEY AUDIT REPORT\n========================================" >> "$LOGFILE"
	echo "Hostname: $hostname" >> "$LOGFILE"
	echo "Date: $date" >> "$LOGFILE"
	return 0
}

key_info(){
	while IFS=: read -r username password uid gid info home_dir shell;
	do
		if [[ -d "$home_dir" ]]
		then
			if [[ -d "$home_dir/.ssh" ]]
			then
				echo "ssh directory exist for user: $username"
				if [[ -f "$home_dir/.ssh/authorized_keys" ]]
				then
					count_key=$(wc -l < "$home_dir/.ssh/authorized_keys")
					echo "User [$username]: authorized_keys FILE EXISTS. Total Keys: $count_key"
				else
					echo "file doesn't exist"
				fi
			else
				echo "SSH Directory doesn't exist"
			fi
		else
			echo "home directory doesn't exist for user: $username"
		fi
	done < /etc/passwd >> "$LOGFILE"
	return 0
}

if key_info
then
	echo "Key check successful"
	exit 0
else
	echo "Key Check fail"
	exit 1
fi
