#!/bin/bash

trap 'echo "Someone has pressed CTRL+C"; exit 1' INT

LOGFILE="/tmp/prepost_validation.log"

pre_post(){

        svc="$1"
        mpt="$2"
        file="$3"

        echo -e "========================================"
        echo "PRE-CHANGE VALIDATION"
        echo -e "========================================"

        # Service existence check
        if ! systemctl cat "$svc" &>/dev/null
        then
                echo "Service doesn't exist: $svc"
                return 1
        fi

        # Pre-change service state
        pre_svc_state=$(systemctl is-active "$svc")
        pre_svc_enable=$(systemctl is-enabled "$svc" 2>/dev/null)

        echo "Service       : $svc"
        echo "Service State : $pre_svc_state"
        echo "Boot Enabled  : $pre_svc_enable"

        # Pre-change mount state
        if findmnt "$mpt" &>/dev/null
        then
                pre_mount_state="MOUNTED"
        else
                pre_mount_state="NOT_MOUNTED"
        fi

        echo "Mount Point   : $mpt"
        echo "Mount State   : $pre_mount_state"

        # Optional file check
        if [[ -n "$file" ]]
        then
                if [[ -e "$file" ]]
                then
                        pre_file_state="EXISTS"
                else
                        pre_file_state="NOT_EXISTS"
                fi

                echo "File          : $file"
                echo "File State    : $pre_file_state"
        fi

        echo
        echo "========================================"
        echo "PERFORM CHANGE"
        echo "========================================"

        read -p "Do you want to restart the service? (yes/no): " ans

        if [[ "$ans" == "yes" || "$ans" == "Yes" ]]
        then
                if systemctl restart "$svc"
                then
                        echo "Service restart command successful"
                else
                        echo "Service restart command failed"
                fi
        else
                echo "Change aborted"
                return 1
        fi

        echo
        echo "========================================"
        echo "POST-CHANGE VALIDATION"
        echo "========================================"

        # Fresh post-change service state
        post_svc_state=$(systemctl is-active "$svc")
        post_svc_enable=$(systemctl is-enabled "$svc" 2>/dev/null)

        echo "Service State : $post_svc_state"
        echo "Boot Enabled  : $post_svc_enable"

        # Fresh post-change mount state
        if findmnt "$mpt" &>/dev/null
        then
                post_mount_state="MOUNTED"
        else
                post_mount_state="NOT_MOUNTED"
        fi

        echo "Mount State   : $post_mount_state"

        # Fresh post-change file state
        if [[ -n "$file" ]]
        then
                if [[ -e "$file" ]]
                then
                        post_file_state="EXISTS"
                else
                        post_file_state="NOT_EXISTS"
                fi

                echo "File State    : $post_file_state"
        fi

        echo
        echo "========================================"
        echo "VALIDATION SUMMARY"
        echo "========================================"

        # Service validation
        if [[ "$post_svc_state" == "active" ]]
        then
                echo "Service      : PASS"
                service_result="PASS"
        else
                echo "Service      : FAIL"
                service_result="FAIL"
        fi

        # Mount validation
        if [[ "$post_mount_state" == "$pre_mount_state" ]]
        then
                echo "Mount Point  : PASS"
                mount_result="PASS"
        else
                echo "Mount Point  : FAIL"
                mount_result="FAIL"
        fi

        # Optional file validation
        if [[ -n "$file" ]]
        then
                if [[ "$post_file_state" == "$pre_file_state" ]]
                then
                        echo "File         : PASS"
                        file_result="PASS"
                else
                        echo "File         : FAIL"
                        file_result="FAIL"
                fi
        fi

        # Overall result
        if [[ "$service_result" == "PASS" && "$mount_result" == "PASS" ]]
        then
                if [[ -z "$file" || "$file_result" == "PASS" ]]
                then
                        echo "Overall      : PASS"
                else
                        echo "Overall      : FAIL"
                fi
        else
                echo "Overall      : FAIL"
        fi
}

# Argument validation
if [[ $# -lt 2 || $# -gt 3 ]]
then
        echo "Usage: $0 <service> <mountpoint> [file]"
        exit 1
fi

pre_post "$@" >> "$LOGFILE"
