#!/bin/bash
trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/errorlog"
error=0
failed=0
warning=0
critical=0
os_report(){
	echo -e "========================================\nERROR LOG ANALYZER\n========================================" >> "$LOGFILE"
	echo "Hostname: $(hostname)" >> "$LOGFILE"
	echo "Log File is: "$logfile"" >> "$LOGFILE"
}

error_analyzer(){
	patterns=("ERROR" "FAILED" "WARNING" "CRITICAL")
	for pattern in "${patterns[@]}"
	do
		count=$(grep -ic "$pattern" "$logfile")
		if [[ "$count" -ne 0 ]]
		then
			echo "$pattern: $count"
		else
			echo "$pattern: No Events" 
		fi
		
	done
	while read -r line
	do
		if [[ "$line" == *"ERROR"* ]]
		then
			echo "Error line detected"
			((error++))
		elif [[ "$line" == *"WARNING"* ]]
		then
			echo "Warning detected"
			((warning++))
		elif [[ "$line" == *"FAILED"* ]]
		then
			echo "Failed attempt detected"
			((failed++))
		else
			echo "Crtitical attempt detected"
			((critical++))
		fi
	done < <(grep -Ei "ERROR|FAILED|WARNING|CRITICAL" "$logfile")
	if [[ "$critical" -gt 0 ]]
	then
		echo "Status: Critical"
	elif [[ "$error" -gt 0 || "$failed" -gt 0 ]]
	then	
		echo "Status: Warning"
	else
		echo "Status: Healthy"
	fi
} >> "$LOGFILE"

log_parser(){
	while getopts "a:b" opt
	do
		case "$opt" in
			a)
				logfile="$OPTARG"
				;;
			b)
				#help
				;;
			*)
				#invalid line
				;;
		esac
	done
}
log_parser "$@"
os_report
error_analyzer
