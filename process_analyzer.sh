#!/bin/bash

trap 'echo "Someone has pressed CTRL+C"; exit 1' INT

LOGFILE="/tmp/processanalyze.log"


process_analyzer(){

        pid="$1"

        echo -e "========================================"
        echo "PROCESS RESOURCE REPORT"
        echo -e "========================================"

        # Validate PID
        if ! kill -0 "$pid" &>/dev/null
        then
                echo "Process with PID $pid does not exist or cannot be accessed"
                return 1
        fi

        # Get process information
        input=$(ps -p "$pid" -o pid,user,%cpu,%mem,stat,cmd | tail -n 1)

        while read -r prc usr cpu mem stat cmd
        do
		cpu_usage=$(printf "%.0f" "$cpu")
                memory_usage=$(printf "%.0f" "$mem")

                echo "PID       : $prc"
                echo "USER      : $usr"
                echo "CPU       : $cpu%"
                echo "MEMORY    : $mem%"
                echo "STATE     : $stat"
                echo "COMMAND   : $cmd"

                echo

                # CPU status
                if [[ "$cpu_usage" -ge 80 ]]
                then
                        echo "CPU Status    : CRITICAL"
                elif [[ "$cpu_usage" -ge 50 ]]
                then
                        echo "CPU Status    : WARNING"
                else
                        echo "CPU Status    : HEALTHY"
                fi

                # Memory status
                if [[ "$memory_usage" -ge 80 ]]
                then
                        echo "Memory Status : CRITICAL"
                elif [[ "$memory_usage" -ge 50 ]]
                then
                        echo "Memory Status : WARNING"
                else
                        echo "Memory Status : HEALTHY"
                fi

        done <<< "$input"

} >> "$LOGFILE"


# Validate argument count

if [[ "$#" -ne 1 ]]
then
        echo "Usage: $0 <PID>"
        exit 1
fi


process_analyzer "$1"
