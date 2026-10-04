#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/process_cleanup.log"

process_cleanup(){
	read -p "Enter the PID which you want to clean: " prc
	echo "1) Show Process Details"
	echo "2) Send SIGTERM"
	echo "3) Send SIGKILL"
	echo "4) Exit"
	read -p  "Choose an option: " opt

	case "$opt" in
		1)
			ps -p "$prc" -o pid,user,%cpu,%mem,stat,cmd
			;;
		2)
			kill -15 "$prc"
			sleep 2
			if kill -0 "$prc" &>/dev/null
			then
				echo "Process is still running"
			else
				echo "Process Terminated Successfully"
				echo "$(date) PID=$prc Action=SIGTERM" >> "$LOGFILE"
			fi
			;;
		3)
			read -p "Are you want to kill(yes/no): " ans
			if [[ "$ans" == "yes" ]]
			then
				kill -9 "$prc"
				sleep 2
				if kill -0 "$prc" &>/dev/null
				then
					echo "Process is still running"
				else
					echo "Process Terminated Successfully"
					echo "$(date) PID=$prc Action=SIGKILL" >> "$LOGFILE"
				fi
			else
				echo "aborting the kill"
			fi
			;;
		4)
			return
			;;
		*)
			echo "Invalid option"
			;;
	esac
} >> "$LOGFILE"

process_cleanup

