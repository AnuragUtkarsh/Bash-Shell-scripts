#!/bin/bash

trap 'echo "\nSomeone has pressed Ctrl+C"; exit 1' INT
if [[ $EUID -ne 0 ]]
then
	echo "Run this script as root"
	exit 1
fi

read -p "Enter Username need to be created: " user
if [[ -z "$user" ]]
then
	echo "Username cannot be empty"
	exit 1
elif [[ ! "$user" =~ ^[a-z_][a-z0-9_-]*$ ]]
then
	echo "invalid username"
	exit 1
fi
read -p "Enter Full name: " fname
read -p "Enter the Shell for user: " shell
if [[ "$shell" == /bin/bash ]]
then
	echo "shell is valid"
else
	echo "Choose a valid shell"
fi

if  id -u "$user" &> /dev/null
then
	echo "User Already Exist"
	exit 1
else
	echo "Creating user"
	useradd -s "$shell" -c "$fname" "$user"
fi

if [[ $? -eq 0 ]]
then
	echo "User creation has been successful"
	exit 0
else
	echo "user creation has failed"
	exit 1
fi
