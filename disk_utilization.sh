#!/bin/bash

LOGFILE=/tmp/disk_report.log

# Humne trap ko sabse upar rakh diya taaki poori script me CTRL+C kaam kare
trap 'echo -e "\nSomeone has pressed CTRL+C"; exit 1' INT

function disk_check {
        echo "========== DISK REPORT ==========" >> "$LOGFILE"
        echo "Hostname: $(hostname)" >> "$LOGFILE"
        echo "Date: $(date)" >> "$LOGFILE"
        echo "File System Use: $(df -h)" >> "$LOGFILE"
        
        # FIX 1: df -h ka output directly while loop me pipe (|) kiya hai
        df -h | awk 'NR>1{print $1,$5}' | while read -r filesystem usage;
        do
                use_num=$(echo "$usage" | tr -d '%')
                
                if [[ "$use_num" -gt 35 ]]
                then
                        echo "CRITICAL: $filesystem is at $usage" | tee -a "$LOGFILE"
                else
                        echo "Threshold OK: $filesystem is at $usage" | tee -a "$LOGFILE"
                fi
        done 
	return 0
} 

disk_check

# Check if function ran successfully
if [[ $? -eq 0 ]]
then
        echo "Disk check successful"
	exit 0
else
        echo "Disk Check failed"
	exit 1
fi
