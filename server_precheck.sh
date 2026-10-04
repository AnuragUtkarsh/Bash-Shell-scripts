#!/bin/bash

trap 'echo "Someone has pressed CTRL+C"; exit 1' INT

LOGFILE="/tmp/server_precheck.log"

pass=0
fail=0
warning=0
total=0

cpu_avg(){

        ((total++))

        cpu_count=$(nproc)
        load_5min=$(awk '{print $2}' /proc/loadavg)

        cpu_usage=$(awk -v load5="$load_5min" -v cpu="$cpu_count" \
        'BEGIN {printf "%.0f", (load/cpu)*100}')

        if [[ "$cpu_usage" -lt 80 ]]
        then
                echo "CPU Load       : PASS (${cpu_usage}%)"
                ((pass++))
        elif [[ "$cpu_usage" -lt 90 ]]
        then
                echo "CPU Load       : WARNING (${cpu_usage}%)"
                ((warning++))
        else
                echo "CPU Load       : FAIL (${cpu_usage}%)"
                ((fail++))
        fi

} >> "$LOGFILE"


memory_avg(){

        ((total++))

        memory_used=$(awk '
        /MemTotal/     {total=$2}
        /MemAvailable/ {avail=$2}
        END {
                printf "%.0f", ((total-avail)/total)*100
        }' /proc/meminfo)

        if [[ "$memory_used" -lt 80 ]]
        then
                echo "Memory Usage   : PASS (${memory_used}%)"
                ((pass++))
        elif [[ "$memory_used" -lt 90 ]]
        then
                echo "Memory Usage   : WARNING (${memory_used}%)"
                ((warning++))
        else
                echo "Memory Usage   : FAIL (${memory_used}%)"
                ((fail++))
        fi

} >> "$LOGFILE"


file_check(){

        ((total++))

        root_usage=$(df -h / | awk 'NR>1 {gsub("%",""); print $5}')

        if [[ "$root_usage" -lt 80 ]]
        then
                echo "Root Filesystem : PASS (${root_usage}%)"
                ((pass++))
        elif [[ "$root_usage" -lt 90 ]]
        then
                echo "Root Filesystem : WARNING (${root_usage}%)"
                ((warning++))
        else
                echo "Root Filesystem : FAIL (${root_usage}%)"
                ((fail++))
        fi

} >> "$LOGFILE"


file_inode(){

        ((total++))

        inode_usage=$(df -ih / | awk 'NR>1 {gsub("%",""); print $5}')

        if [[ "$inode_usage" -lt 80 ]]
        then
                echo "Root Inode      : PASS (${inode_usage}%)"
                ((pass++))
        elif [[ "$inode_usage" -lt 90 ]]
        then
                echo "Root Inode      : WARNING (${inode_usage}%)"
                ((warning++))
        else
                echo "Root Inode      : FAIL (${inode_usage}%)"
                ((fail++))
        fi

} >> "$LOGFILE"


dns_check(){

        ((total++))

        if getent hosts google.com &>/dev/null
        then
                echo "DNS             : PASS"
                ((pass++))
        else
                echo "DNS             : FAIL"
                ((fail++))
        fi

} >> "$LOGFILE"


gateway_check(){

        ((total++))

        gateway=$(ip route | awk '/default/ {print $3; exit}')

        if [[ -z "$gateway" ]]
        then
                echo "Gateway         : FAIL (No default gateway)"
                ((fail++))
                return
        fi

        if ping -c 2 -W 2 "$gateway" &>/dev/null
        then
                echo "Gateway         : PASS ($gateway)"
                ((pass++))
        else
                echo "Gateway         : FAIL ($gateway)"
                ((fail++))
        fi

} >> "$LOGFILE"


service_check(){

        services=("sshd" "chronyd" "firewalld")

        for i in "${services[@]}"
        do

                ((total++))

                if systemctl is-active "$i" &>/dev/null
                then
                        echo "$i : PASS"
                        ((pass++))
                else
                        echo "$i : FAIL"
                        ((fail++))
                fi

        done

} >> "$LOGFILE"


echo -e "========================================" >> "$LOGFILE"
echo "SERVER READINESS CHECK" >> "$LOGFILE"
echo -e "========================================" >> "$LOGFILE"
echo "Hostname : $(hostname)" >> "$LOGFILE"
echo "Date     : $(date)" >> "$LOGFILE"
echo >> "$LOGFILE"


cpu_avg
memory_avg
file_check
file_inode
dns_check
gateway_check
service_check


echo >> "$LOGFILE"
echo -e "========================================" >> "$LOGFILE"
echo "VALIDATION SUMMARY" >> "$LOGFILE"
echo -e "========================================" >> "$LOGFILE"

echo "Total Checks : $total" >> "$LOGFILE"
echo "Passed       : $pass" >> "$LOGFILE"
echo "Warnings     : $warning" >> "$LOGFILE"
echo "Failed       : $fail" >> "$LOGFILE"

if [[ "$fail" -gt 0 ]]
then
        echo "Overall Status : NOT READY" >> "$LOGFILE"
elif [[ "$warning" -gt 0 ]]
then
        echo "Overall Status : READY WITH WARNING" >> "$LOGFILE"
else
        echo "Overall Status : READY" >> "$LOGFILE"
fi

echo -e "========================================" >> "$LOGFILE"
