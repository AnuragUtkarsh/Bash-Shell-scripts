#!/bin/bash

trap 'echo "Someone has pressed CTRL+C";exit 1' INT

LOGFILE="/tmp/network.log"

read -p "Enter the interface where you want to add the IP: " int
read -p "Enter the Ip need to be added(1.2.3.4): " ip
read -p "Enter the subnet need to be added(22,24): " snet

configure_interface(){
	echo -e "========================================\nNETWORK CONFIGURATION REPORT\n========================================"
	interface_found=false
	#verify the device
	for i in  $(nmcli connection show | awk 'NR>1 {print $4}')
	do
		if [[ "$i" == "$int" ]]
		then
			interface_found=true
			break 
		fi
	done
	if [[ "$interface_found" == false ]]
	then
		echo "Interface doesn't exist"
		return 1
	fi
	echo "Interface exists"

	#configure interface
	nmcli connection add type ethernet ifname "$int" con-name "$int" ipv4.address "${ip}/${snet}" ipv4.method manual
	#activation connection
	if nmcli connection up "$int"
	then
		echo "Connection has been added successfully"
	else
		echo "Connection add failed"
		return 1
	fi
}>> "$LOGFILE"
add_secondary_ip(){
	        echo -e "========================================\nNETWORK CONFIGURATION REPORT\n========================================"
        interface_found=false
        #verify the device
        for i in  $(nmcli connection show | awk 'NR>1 {print $4}')
        do
                if [[ "$i" == "$int" ]]
                then
                        interface_found=true
                        break
                fi
        done
        if [[ "$interface_found" == false ]]
        then
                echo "Interface doesn't exist"
                return 1
        fi
        echo "Interface exists"
	#modify the interface
	nmcli connection modify "$int" +ipv4.addresses "${ip}/${snet}" 
	if nmcli connection up "$int"
	then
		echo "Secondary IP has been added"
	else
		echo "Ip addition failed"
		return 1
	fi
} >> "$LOGFILE"
echo "========================================"
echo "       NETWORK CONFIGURATION"
echo "========================================"
echo "1) Configure IP on Interface"
echo "2) Add Secondary / Virtual IP"
echo "========================================"
read -p "Choose Option(1/2): " opt
case "$opt" in 
	1)
		configure_interface
		;;
	2)
		add_secondary_ip
		;;
	*)
		echo "Invalid option"
		exit 1
		;;
esac
