#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/linux-compliance.log"

os_info(){
	echo -e "========================================\nLINUX COMPLIANCE REPORT\n========================================" >> "$LOGFILE"
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Date: $(date)" >> "$LOGFILE"
}

ssh_info(){
	root_login=$(root_login=$(grep -E '^[[:space:]]*PermitRootLogin[[:space:]]+' /etc/ssh/sshd_config | awk '{print $2}'))
	if [[ "$root_login" == "yes" ]]
	then
		echo "Root Login: Enabled"
	else
		echo "Root Login: Disabled"
	fi
	empty_password=$(awk -F: '$2 == "" {print $1}' /etc/shadow|wc -l)
	if [[ "$empty_password" -eq 0 ]]
	then
		echo "Empty Password Users: PASS"
	else
		echo "Empty Password Users: FAIL"
	fi
	suid_files=$(find / -perm /4000 -type f -print 2>/dev/null| wc -l)
	if [[ "$suid_files" -eq 0 ]]
	then
		echo "SUID Audit: Failed"
	else
		echo "SUID Audit: Passed"
	fi
	sgid_files=$(find / -perm /2000 -type f 2>/dev/null| wc -l)
        if [[ "$sgid_files" -eq 0 ]]
        then
                echo "SGID Audit: Failed"
        else
                echo "SGID Audit: Passed"
        fi
	writable_files=$(find / -perm -o+w -type f 2>/dev/null| wc -l)
	if [[ "$writable_files" -eq 0 ]]
	then
		echo "No writable files"
	else
		echo "Writable files present"
	fi
	writable_directory=$(find / -perm -o+w -type d 2>/dev/null| wc -l)
	if [[ "$writable_directory" -eq 0 ]]
        then
                echo "No writable directory"
        else
                echo "Writable directory present"
        fi
	failed_login=$(grep -i failed /var/log/secure| wc -l)
	if [[ "$failed_login" -eq 0 ]]
	then
		echo "No failed login"
	else
		echo "failed login present"
	fi
	services=( "sshd" "firewalld")
        for svc in "${services[@]}"
	do
		if systemctl is-active --quiet "$svc"
		then
			echo "Service is active"
		else
			echo "Service is Inactive"
		fi
	done
	if [[ $(getenforce) == "enforcing" ]]
	then
		echo "SeLinux is active"
	else
		echo "Selinux is not active"
	fi
} >> "$LOGFILE"
os_info
ssh_info
