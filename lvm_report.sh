#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/lvm_log.txt"

os_info(){
	echo -e "========================================\nLVM REPORT\n========================================" >> "$LOGFILE"
	echo "HOSTNAME: $(hostname)" >> "$LOGFILE"
	echo "Date: $(date)" >> "$LOGFILE"
}
check_lvmtools(){
	if ! command -v pvs &>/dev/null
	then
		echo "LVM Tool Doesn't Exist" >> "$LOGFILE"
		return 1
	fi
	return 0
}

pv_report(){
	echo "--- PHYSICAL VOLUMES ---" >> "$LOGFILE"
	pvs -o pv_name,vg_name,pv_size,pv_free >> "$LOGFILE" 
}

vg_report(){
	echo "--- VOLUME GROUPS ---" >> "$LOGFILE"
	vgs -o vg_name,pv_count,lv_count,vg_size,vg_free >> "$LOGFILE"	
}

lv_report(){
        echo "--- LOGICAL VOLUMES ---" >> "$LOGFILE"
        lvs -o lv_name,vg_name,lv_size,lv_path >> "$LOGFILE"
}

if ! check_lvmtools
then
	exit 1
fi
os_info
pv_report
vg_report
lv_report

