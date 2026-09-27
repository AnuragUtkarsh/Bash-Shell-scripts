#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/linuxsecurity.log"
pass=0
warning=0
os_report(){
	echo -e "========================================\nLINUX SECURITY CHECK\n========================================" >> "$LOGFILE"
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Date: $(date)" >> "$LOGFILE"
}

ssh_check(){
	echo "[SSH CONFIGURATION]"
	root_login=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')
	if [[ "$root_login" == "yes"i ]]
	then
		echo "Root Login: ENABLED"
		((warning++))
	else
		echo "Root Login: DISABLED"
		((pass++))
	fi

	echo "[USER SECURITY]"
	empty_users=$(awk -F: '($2=="") {print $1}' /etc/shadow | wc -l)
	if [[ "$empty_users" -eq 0 ]]
	then
		echo "Empty Password Users: 0"
		((pass++))
	else
		echo "Empty password user: $empty_users"
		((warning++))
	fi

	echo "[SUID FILES]"
	suid_files=$(find / -type f -perm -4000 -print 2>/dev/null | wc -l)
	echo "SUID file count is: $suid_files"

	echo "[WORLD-WRITABLE FILES]"
	world_writable=$(find / -type f -perm -0002 -print 2>/dev/null| wc -l)
	echo "Total World writable file: $world_writable"

	echo "[SSH FAILED LOGINS]"
	failed_login=$(grep -i failed /var/log/secure|wc -l)
	echo "Failed Attempts: $failed_login"
} >> "$LOGFILE"

function summary {
	echo -e "========================================\nSECURITY SUMMARY\n========================================" >> "$LOGFILE"
	echo "Total check pass: $pass" >> "$LOGFILE"
	echo "Total Warning: $warning" >> "$LOGFILE"
	if [[ $pass -ge $warning ]]
	then
		echo "Overall Status: Passed" >> "$LOGFILE"
	else
		echo "Overall Status: WARNING" >> "$LOGFILE"
	fi
}

os_report
ssh_check
summary
