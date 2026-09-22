#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/ping_response"
up=0
down=0
os_report(){
        echo -e "========================================\nMULTI-SERVER PING REPORT\n========================================" >> "$LOGFILE"
        echo "Hostname: $(hostname)" >> "$LOGFILE"
        echo "Date: $(date)" >> "$LOGFILE"
}

ping_servers(){
        for server in "${servers[@]}"
        do
                if ping -c2 -W2 "$server" &>/dev/null
                then
                        ((up++))
                else
                        ((down++))
                fi
        done
} >> "$LOGFILE"

parse_option(){
        while getopts "s:h" opt
        do
                case "$opt" in
                        s)
                                read -a servers <<< "$OPTARG"
                                ;;
                        h)
                                #help
                                ;;
                        *)
                                #invalid
                                ;;
                esac
        done
}

parse_option "$@"
os_report
ping_servers
echo "Total servers: "${#servers[@]}"" >> "$LOGFILE"
echo "Up: "$up"" >> "$LOGFILE"
echo "Down: "$down"" >> "$LOGFILE"
#./ping_checker.sh -s "app01 app02 192.168.198.250"
