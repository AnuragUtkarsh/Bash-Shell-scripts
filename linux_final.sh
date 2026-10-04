#!/bin/bash

trap 'echo "Someone has pressed CTRL+C"; exit 1' INT

LOGFILE="/tmp/linux_operations.log"

# ============================================================
# USER / GROUP PROVISIONING
# ============================================================

user_provision(){

        read -p "Enter username: " usr
        read -p "Enter primary group: " pgrp
        read -p "Enter secondary groups (comma separated): " sgrp
        read -p "Enter shell: " shl
        read -p "Enter home directory: " hdir

        if ! grep -Fxq "$shl" /etc/shells
        then
                echo "Invalid shell: $shl"
                return 1
        fi

        if ! getent group "$pgrp" &>/dev/null
        then
                echo "Creating primary group: $pgrp"

                if ! groupadd "$pgrp"
                then
                        echo "Failed to create primary group"
                        return 1
                fi
        fi

        if id "$usr" &>/dev/null
        then
                echo "User already exists: $usr"
        else
                if useradd -m -d "$hdir" -s "$shl" -g "$pgrp" "$usr"
                then
                        echo "User created successfully: $usr"
                else
                        echo "User creation failed"
                        return 1
                fi
        fi

        if [[ -n "$sgrp" ]]
        then
                IFS=',' read -ra secondary_groups <<< "$sgrp"

                for grp in "${secondary_groups[@]}"
                do
                        if ! getent group "$grp" &>/dev/null
                        then
                                groupadd "$grp"
                        fi

                        usermod -aG "$grp" "$usr"
                done
        fi

        echo "User provisioning completed"
}


# ============================================================
# LVM CREATE
# ============================================================

lvm_create(){

        read -p "Enter disk name (example: sdb): " dsk
        read -p "Enter Volume Group name: " vg
        read -p "Enter Logical Volume name: " lv
        read -p "Enter LV size in GB: " lsize
        read -p "Enter filesystem type (xfs/ext4): " fstype
        read -p "Enter mount point: " mpt

        if [[ "$mpt" != /* ]]
        then
                echo "Mount point must be absolute"
                return 1
        fi

        if [[ ! -b "/dev/$dsk" ]]
        then
                echo "Disk /dev/$dsk does not exist"
                return 1
        fi

        if ! command -v pvcreate &>/dev/null
        then
                echo "LVM tools not installed"
                return 1
        fi

        if pvs "/dev/$dsk" &>/dev/null
        then
                echo "Disk already belongs to a PV"
                return 1
        fi

        echo "Creating Physical Volume..."
        if ! pvcreate "/dev/$dsk"
        then
                echo "PV creation failed"
                return 1
        fi

        if vgdisplay "$vg" &>/dev/null
        then
                echo "VG already exists: $vg"
        else
                if ! vgcreate "$vg" "/dev/$dsk"
                then
                        echo "VG creation failed"
                        return 1
                fi
        fi

        if lvdisplay "/dev/$vg/$lv" &>/dev/null
        then
                echo "LV already exists"
                return 1
        fi

        if ! lvcreate -L "${lsize}G" -n "$lv" "$vg"
        then
                echo "LV creation failed"
                return 1
        fi

        if [[ "$fstype" == "xfs" ]]
        then
                mkfs.xfs "/dev/$vg/$lv"
        elif [[ "$fstype" == "ext4" ]]
        then
                mkfs.ext4 "/dev/$vg/$lv"
        else
                echo "Unsupported filesystem"
                return 1
        fi

        mkdir -p "$mpt"

        uuid=$(blkid -s UUID -o value "/dev/$vg/$lv")

        if ! grep -qE "[[:space:]]$mpt[[:space:]]" /etc/fstab
        then
                echo "UUID=$uuid $mpt $fstype defaults 0 0" >> /etc/fstab
        fi

        mount -av

        if findmnt "$mpt" &>/dev/null
        then
                echo "LVM creation and mount successful"
        else
                echo "Mount validation failed"
                return 1
        fi
}


# ============================================================
# LVM EXTEND
# ============================================================

lvm_extend(){

        read -p "Enter mount point: " mpt
        read -p "Enter new size in GB: " nsize

        lv=$(findmnt "$mpt" -o SOURCE -n)

        if [[ -z "$lv" ]]
        then
                echo "Mount point not found"
                return 1
        fi

        current_size=$(lvs --noheadings --units b --nosuffix \
                -o lv_size "$lv" | xargs)

        new_size=$(numfmt --from=iec "${nsize}G")

        if [[ "$new_size" -le "$current_size" ]]
        then
                echo "New size must be greater than current size"
                return 1
        fi

        if lvextend -L "${nsize}G" "$lv" -r
        then
                echo "LV extension successful"
        else
                echo "LV extension failed"
                return 1
        fi

        echo "New filesystem status:"
        df -hT "$mpt"
}


# ============================================================
# NETWORK CONFIGURATION
# ============================================================

network_config(){

        echo "========================================"
        echo "NETWORK CONFIGURATION"
        echo "========================================"
        echo "1) Configure IP on Interface"
        echo "2) Add Secondary IP"
        echo "3) Exit"

        read -p "Choose option: " opt

        read -p "Enter interface: " int
        read -p "Enter IP address: " ip
        read -p "Enter subnet (example: 24): " snet

        if ! nmcli device status | awk 'NR>1 {print $1}' | grep -Fxq "$int"
        then
                echo "Interface does not exist"
                return 1
        fi

        case "$opt" in

                1)
                        if nmcli connection show "$int" &>/dev/null
                        then
                                nmcli connection modify "$int" \
                                ipv4.addresses "${ip}/${snet}" \
                                ipv4.method manual
                        else
                                nmcli connection add \
                                type ethernet \
                                ifname "$int" \
                                con-name "$int" \
                                ipv4.addresses "${ip}/${snet}" \
                                ipv4.method manual
                        fi

                        if nmcli connection up "$int"
                        then
                                echo "IP configuration successful"
                        else
                                echo "IP configuration failed"
                        fi
                        ;;

                2)
                        if nmcli connection modify "$int" \
                        +ipv4.addresses "${ip}/${snet}"
                        then
                                nmcli connection up "$int"
                                echo "Secondary IP added successfully"
                        else
                                echo "Secondary IP configuration failed"
                        fi
                        ;;

                3)
                        return
                        ;;

                *)
                        echo "Invalid option"
                        ;;
        esac
}


# ============================================================
# SERVICE RECOVERY
# ============================================================

service_recovery(){

        read -p "Enter service name: " svc

        if ! systemctl cat "$svc" &>/dev/null
        then
                echo "Service does not exist"
                return 1
        fi

        act=$(systemctl is-active "$svc")
        enab=$(systemctl is-enabled "$svc" 2>/dev/null)

        if [[ "$act" == "active" ]]
        then
                echo "Service: $svc"
                echo "Status: ACTIVE"
                echo "Boot Enabled: $enab"
                echo "No recovery required"
                return
        fi

        echo "Service is not running"
        echo "Recent logs:"
        journalctl -u "$svc" -n 10 --no-pager

        read -p "Do you want to restart the service? (yes/no): " ans

        if [[ "$ans" == "yes" || "$ans" == "Yes" ]]
        then
                if systemctl restart "$svc"
                then
                        act_after=$(systemctl is-active "$svc")

                        if [[ "$act_after" == "active" ]]
                        then
                                echo "Service restarted successfully"
                        else
                                echo "Service restart failed"
                        fi
                else
                        echo "Restart command failed"
                fi
        else
                echo "Restart aborted"
        fi
}


# ============================================================
# PACKAGE AUDIT
# ============================================================

package_audit(){

        read -p "Enter package name: " pkg

        if rpm -q "$pkg" &>/dev/null
        then
                echo "Package       : $pkg"
                echo "Status        : INSTALLED"
                echo "Version       : $(rpm -q "$pkg" --queryformat '%{VERSION}-%{RELEASE}\n')"
                echo "Architecture  : $(rpm -q "$pkg" --queryformat '%{ARCH}\n')"
        else
                echo "Package       : $pkg"
                echo "Status        : NOT INSTALLED"
        fi

        echo
        echo "Total Installed Packages: $(rpm -qa | wc -l)"

        echo
        echo "Last 10 Installed Packages:"
        rpm -qa --last | head -n 10
}


# ============================================================
# CONFIGURATION BACKUP
# ============================================================

config_backup(){

        read -p "Enter backup directory: " bkp_dir

        mkdir -p "$bkp_dir"

        configs=(
                "/etc/fstab"
                "/etc/hosts"
                "/etc/ssh/sshd_config"
                "/etc/resolv.conf"
                "/etc/sysctl.conf"
        )

        success=0
        failed=0

        for file in "${configs[@]}"
        do
                if [[ ! -e "$file" ]]
                then
                        echo "$file : NOT FOUND"
                        ((failed++))
                        continue
                fi

                fname=$(basename "$file")
                backup_file="${bkp_dir}/${fname}_bkp_$(date +%Y%m%d_%H%M%S)"

                if cp -avp "$file" "$backup_file" &>/dev/null
                then
                        if [[ -e "$backup_file" ]]
                        then
                                echo "$file : BACKED UP"
                                ((success++))
                        else
                                echo "$file : VALIDATION FAILED"
                                ((failed++))
                        fi
                else
                        echo "$file : BACKUP FAILED"
                        ((failed++))
                fi
        done

        echo
        echo "Backup Summary"
        echo "Success: $success"
        echo "Failed : $failed"
}


# ============================================================
# SERVER PRECHECK
# ============================================================

server_precheck(){

        pass=0
        warning=0
        fail=0
        total=0

        echo "========================================"
        echo "SERVER READINESS CHECK"
        echo "========================================"

        # CPU
        ((total++))

        cpu_count=$(nproc)
        load_5min=$(awk '{print $2}' /proc/loadavg)

        cpu_usage=$(awk -v load5="$load_5min" -v cores="$cpu_count" \
        'BEGIN {printf "%.0f", (load5/cores)*100}')

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

        # Memory
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

        # Root filesystem
        ((total++))

        root_usage=$(df -h / | awk 'NR>1 {gsub("%",""); print $5}')

        if [[ "$root_usage" -lt 80 ]]
        then
                echo "Root Filesystem: PASS (${root_usage}%)"
                ((pass++))
        elif [[ "$root_usage" -lt 90 ]]
        then
                echo "Root Filesystem: WARNING (${root_usage}%)"
                ((warning++))
        else
                echo "Root Filesystem: FAIL (${root_usage}%)"
                ((fail++))
        fi

        # Root inode
        ((total++))

        inode_usage=$(df -ih / | awk 'NR>1 {gsub("%",""); print $5}')

        if [[ "$inode_usage" -lt 80 ]]
        then
                echo "Root Inode     : PASS (${inode_usage}%)"
                ((pass++))
        elif [[ "$inode_usage" -lt 90 ]]
        then
                echo "Root Inode     : WARNING (${inode_usage}%)"
                ((warning++))
        else
                echo "Root Inode     : FAIL (${inode_usage}%)"
                ((fail++))
        fi

        # DNS
        ((total++))

        if getent hosts google.com &>/dev/null
        then
                echo "DNS            : PASS"
                ((pass++))
        else
                echo "DNS            : FAIL"
                ((fail++))
        fi

        # Gateway
        ((total++))

        gateway=$(ip route | awk '/default/ {print $3; exit}')

        if [[ -n "$gateway" ]] && ping -c2 -W2 "$gateway" &>/dev/null
        then
                echo "Gateway        : PASS ($gateway)"
                ((pass++))
        else
                echo "Gateway        : FAIL"
                ((fail++))
        fi

        # Services
        services=("sshd" "chronyd" "firewalld")

        for svc in "${services[@]}"
        do
                ((total++))

                if systemctl is-active "$svc" &>/dev/null
                then
                        echo "$svc          : PASS"
                        ((pass++))
                else
                        echo "$svc          : FAIL"
                        ((fail++))
                fi
        done

        echo
        echo "========================================"
        echo "READINESS SUMMARY"
        echo "========================================"
        echo "Total Checks : $total"
        echo "Passed       : $pass"
        echo "Warnings     : $warning"
        echo "Failed       : $fail"

        if [[ "$fail" -gt 0 ]]
        then
                echo "Overall Status : NOT READY"
        elif [[ "$warning" -gt 0 ]]
        then
                echo "Overall Status : READY WITH WARNING"
        else
                echo "Overall Status : READY"
        fi
}


# ============================================================
# MAIN MENU
# ============================================================

if [[ "$EUID" -ne 0 ]]
then
        echo "This framework must be run as root"
        exit 1
fi

while true
do

        echo
        echo "========================================"
        echo "      LINUX OPERATIONS AUTOMATION"
        echo "========================================"
        echo "Hostname : $(hostname)"
        echo "Date     : $(date)"
        echo "========================================"
        echo "1) User / Group Provisioning"
        echo "2) LVM Create"
        echo "3) LVM Extend"
        echo "4) Network Configuration"
        echo "5) Service Recovery"
        echo "6) Package Audit"
        echo "7) Configuration Backup"
        echo "8) Server Precheck"
        echo "9) Exit"
        echo "========================================"

        read -p "Choose an option: " option

        case "$option" in

                1)
                        user_provision
                        ;;

                2)
                        lvm_create
                        ;;

                3)
                        lvm_extend
                        ;;

                4)
                        network_config
                        ;;

                5)
                        service_recovery
                        ;;

                6)
                        package_audit
                        ;;

                7)
                        config_backup
                        ;;

                8)
                        server_precheck
                        ;;

                9)
                        echo "Exiting Linux Operations Automation"
                        exit 0
                        ;;

                *)
                        echo "Invalid option"
                        ;;

        esac

        echo
        read -p "Press Enter to continue..." dummy

done
