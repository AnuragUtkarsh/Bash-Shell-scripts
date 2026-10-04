#!/bin/bash

trap 'echo "Someone has pressed CTRL+C"; exit 1' INT

LOGFILE="/tmp/backupconfig.log"

success=0
failed=0
total=0

backup_configure(){

        bkp_dir="$1"
        server_label="$2"
        add_file="$3"

        echo "========================================"
        echo "LINUX CONFIGURATION BACKUP"
        echo "========================================"
        echo "Backup Directory : $bkp_dir"
        echo "Server Label     : $server_label"

        if [[ -n "$add_file" ]]
        then
                echo "Additional File  : $add_file"
        fi

        # Create backup directory if not present
        if [[ ! -d "$bkp_dir" ]]
        then
                if mkdir -p "$bkp_dir"
                then
                        echo "Backup directory created"
                else
                        echo "Unable to create backup directory"
                        return 1
                fi
        fi

        # Default configuration files
        default_bkp=(
                "/etc/fstab"
                "/etc/hosts"
                "/etc/ssh/sshd_config"
                "/etc/resolv.conf"
                "/etc/sysctl.conf"
        )

        echo
        echo "========================================"
        echo "DEFAULT CONFIGURATION BACKUP"
        echo "========================================"

        for i in "${default_bkp[@]}"
        do
                ((total++))

                # Check source file
                if [[ ! -e "$i" ]]
                then
                        echo "$i : NOT FOUND"
                        ((failed++))
                        continue
                fi

                fname=$(basename "$i")
                backup_file="${bkp_dir}/${fname}_bkp_$(date +%Y%m%d_%H%M%S)"

                if cp -avp "$i" "$backup_file" &>/dev/null
                then
                        # Validate backup
                        if [[ -e "$backup_file" ]]
                        then
                                echo "$i : BACKED UP"
                                ((success++))
                        else
                                echo "$i : BACKUP VALIDATION FAILED"
                                ((failed++))
                        fi
                else
                        echo "$i : BACKUP FAILED"
                        ((failed++))
                fi
        done

        # Optional additional file
        if [[ -n "$add_file" ]]
        then
                echo
                echo "========================================"
                echo "ADDITIONAL FILE BACKUP"
                echo "========================================"

                ((total++))

                if [[ ! -e "$add_file" ]]
                then
                        echo "$add_file : NOT FOUND"
                        ((failed++))
                else
                        fname=$(basename "$add_file")
                        backup_file="${bkp_dir}/${fname}_bkp_$(date +%Y%m%d_%H%M%S)"

                        if cp -avp "$add_file" "$backup_file" &>/dev/null
                        then
                                if [[ -e "$backup_file" ]]
                                then
                                        echo "$add_file : BACKED UP"
                                        ((success++))
                                else
                                        echo "$add_file : BACKUP VALIDATION FAILED"
                                        ((failed++))
                                fi
                        else
                                echo "$add_file : BACKUP FAILED"
                                ((failed++))
                        fi
                fi
        fi

        # Summary
        echo
        echo "========================================"
        echo "BACKUP SUMMARY"
        echo "========================================"
        echo "Server Label : $server_label"
        echo "Total        : $total"
        echo "Success      : $success"
        echo "Failed       : $failed"

        if [[ "$failed" -eq 0 && "$success" -gt 0 ]]
        then
                echo "Status       : SUCCESS"
        elif [[ "$success" -gt 0 && "$failed" -gt 0 ]]
        then
                echo "Status       : PARTIAL"
        else
                echo "Status       : FAILED"
        fi

        echo "========================================"
}

# Argument validation
if [[ "$#" -lt 2 || "$#" -gt 3 ]]
then
        echo "Usage: $0 <backup_dir> <server_label> [config_file]"
        exit 1
fi

backup_configure "$@" >> "$LOGFILE"
