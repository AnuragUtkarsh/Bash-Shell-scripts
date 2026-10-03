#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/usergroup.log"
if [[ "$EUID" -ne 0 ]]
then
	echo "Script must be run as root">> "$LOGFILE"
	exit 1
fi

os_report(){
	echo -e "========================================\nUSER PROVISIONING REPORT\n========================================" >> "$LOGFILE"
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Date: $(date)" >> "$LOGFILE"
}

user_provision(){
	read -p "Enter the username you want to be create: " usr
	read -p "Enter the primary group of user: " grp
	read -p "Enter the secondary groups(comma seprated): " sgrp
	read -p "Enter the shell for the user: " shl
	read -p "Enter the home directory you want to create: " hdir

	#validate shell
	if grep -Fxq "$shl" /etc/shells
	then
		echo "valid shell"
	else
		echo "shell doesn't exist"
		exit 1
	fi

	#creating group
	if getent group "$grp" &>/dev/null
	then
		echo "Group exist"
	else
		groupadd "$grp"
	fi

	#creating user
	if id -u "$usr" &>/dev/null
	then
		echo "User exist"
	else
		useradd -s "$shl" -m -d "$hdir" -g "$grp" "$usr"
	fi

	#checking secondary group
	IFS=',' read -ra secondary_groups <<< "$sgrp"
	for i in "${secondary_groups[@]}"
	do
		if getent group "$i"
		then
			usermod -aG "$i" "$usr"
		else
			groupadd "$i"
			usermod -aG "$i" "$usr"
		fi
	done
	if id -u "$usr" &>/dev/null
	then
		echo "User created is: $usr" 
	else
		echo "User creation failed"
	fi

} >> "$LOGFILE"
os_report
user_provision
