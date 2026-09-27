#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT
LOGFILE="/tmp/audit_report.txt"
read -p "Enter number of files to be audited: " file
files=()
pass=0
fail=0
not_found=0
os_report(){
	echo -e "========================================\nPERMISSION AUDIT\n========================================" >> "$LOGFILE"
	for ((j=1; j<="$file"; j++))
	do
		read -p "Enter the file name: " item
		if [[ -n "$item" && -e "$item" ]]
		then
			files+=("$item")
		else
			echo "Enter valid value"
		fi
	done
} >> "$LOGFILE"
declare -A expected

expected["/etc/passwd"]="644"
expected["/etc/fstab"]="644"
expected["/etc/ssh/sshd_config"]="600"


permission_audit(){
	for fls in "${files[@]}"
	do
		if [[ -f "$fls" ]]
		then
			while read -r owner group filename permission
			do
				expected_perm="${expected[$fls]}"
				echo "Filename: $filename"
				echo
				echo "Owner: $owner"
				echo
				echo "Group: $group"
				echo
				echo "Actual Permission: $permission"
				echo
				echo "Expected Permission: $expected_perm"
				if [[ "$permission" -eq "$expected_perm" ]]
				then
					echo "Permission Ok"
					((pass++))
				elif [[ "$permission" -ne 644 ]]
				then
					echo "Permission Fail"
					((fail++))
				fi
			done< <(stat -c "%U %G %n %a" "$fls")
		else
			echo "File not exist"
			((not_found++))
		fi
	done
} >> "$LOGFILE"
os_report
if permission_audit
then
	echo "Permission check has been done" >> "$LOGFILE"
else
	echo "Permission check failed" >> "$LOGFILE"
fi
echo "Pass Count: $pass" >> "$LOGFILE"
echo "Failed Count: $fail" >> "$LOGFILE"
echo "Not FOund: $not_found" >> "$LOGFILE"
