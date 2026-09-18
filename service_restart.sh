#!/bin/bash

trap 'echo "Someone has pressed Ctrl+c"; exit 1' INT

LOGFILE="/tmp/service_restart.log"

read -p "Enter the service name: " svc

echo "========================================" >> "$LOGFILE"
echo "SERVICE RESTART AUTOMATION" >> "$LOGFILE"
echo "Hostname: $(hostname)" >> "$LOGFILE"
echo "Date: $(date)" >> "$LOGFILE"
echo "Service: $svc" >> "$LOGFILE"

{
    if systemctl cat "$svc" &>/dev/null
    then
        echo "Service Exists: YES"

        status=$(systemctl is-active "$svc")
        echo "Before Status: $status"

        if [[ "$status" == "active" ]]
        then
            echo "Action: No restart required"
            echo "Result: ALREADY RUNNING"

        elif [[ "$status" == "failed" || "$status" == "inactive" ]]
        then
            echo "Action: Restart attempted"

            if systemctl restart "$svc"
            then
                echo "Restart Command: SUCCESS"

                sleep 2

                after_status=$(systemctl is-active "$svc")
                echo "After Status: $after_status"

                if [[ "$after_status" == "active" ]]
                then
                    echo "Result: SUCCESS"
                else
                    echo "Result: FAILED"
                fi
            else
                echo "Restart Command: FAILED"
                echo "Result: FAILED"
            fi

        else
            echo "Service Status: $status"
            echo "Result: UNKNOWN"
        fi

    else
        echo "Service Exists: NO"
        echo "Result: UNKNOWN"
    fi

} >> "$LOGFILE"

echo "Check completed successfully" >> "$LOGFILE"
echo "========================================" >> "$LOGFILE"
