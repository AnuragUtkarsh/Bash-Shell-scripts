#!/bin/bash

LOGFILE=/tmp/service_health.log

read -p "Enter the Service name to be checked: " svc

echo -e "========================================\nSERVICE HEALTH CHECK\n========================================" >> "$LOGFILE"
echo "Hostname: $(hostname)" >> "$LOGFILE"
echo "Date: $(date)" >> "$LOGFILE"
echo "Service: $svc" >> "$LOGFILE"

{
        if systemctl cat "$svc" &> /dev/null
        then
                status=$(systemctl is-active "$svc")
                boot_status=$(systemctl is-enabled "$svc")
                echo "Service Exists: YES" >> "$LOGFILE"
                if [[ $status == "active" ]]
                then
                        echo "Service Status: active" >> "$LOGFILE"
                        echo "Health: HEALTHY"
                        if [[ $boot_status == "enabled" ]]
                        then
                                echo "Boot Enabled: Enabled" >> "$LOGFILE"
                        else
                                echo "Boot Enabled: Disabled" >> "$LOGFILE"
                        fi
                else
                        echo "Service Status: "$status"" >> "$LOGFILE"
                fi
        else
		echo "Service Exists: NO" >> "$LOGFILE"
                echo "Health: UNKNOWN" >> "$LOGFILE"
        fi
} >> "$LOGFILE"

echo "Check completed successfully" >> "$LOGFILE"
echo "========================================" >> "$LOGFILE"
