#!/bin/bash

trap 'echo "Someone has pressed CTRL+C"; exit 1' INT

LOGFILE="/tmp/linuxops.log"

if [[ "$EUID" -ne 0 ]]
then
        echo "Script must be run as root"
        exit 1
fi


# ============================================================
# USER / GROUP PROVISIONING
# ============================================================

user_provision(){

        read -p "Enter the name of user: " usr
        read -p "Enter the primary group of user: " pgrp
        read -p "Enter the Secondary group of user(a,b): " sgrp
        read -p "Enter the shell of user: " shl
        read -p "Enter the home directory of user: " hdir

        if id -u "$usr" &>/dev/null
        then
                echo "User already exists"
                return 1
        fi

        if ! grep -Fxq "$shl" /etc/shells
        then
                echo "Please enter valid shell"
                return 1
        fi

        if getent group "$pgrp" &>/dev/null
        then
                echo "Primary group exists"
        else
                echo "Creating primary group"
                groupadd "$pgrp" || return 1
        fi

        echo "Creating user"

        if ! useradd -s "$shl" -g "$pgrp" -m -d "$hdir" "$usr"
        then
                echo "User creation failed"
                return 1
        fi

        IFS=',' read -ra secondary_groups <<< "$sgrp"

        for i in "${secondary_groups[@]}"
        do
                if getent group "$i" &>/dev/null
                then
                        echo "Secondary group $i exists"
                else
                        echo "Creating secondary group $i"
                        groupadd "$i" || return 1
                fi

                usermod -aG "$i" "$usr" || return 1
        done

        echo "User provisioning completed successfully"
}


# ============================================================
# LVM CREATE
# ============================================================

lvm_create(){

        read -p "Enter the disk on which you want to create the LVM: " dsk
        read -p "Enter the name of VG: " vg
        read -p "Enter the name of LV: " lv
        read -p "Enter the file system type: " fstype
        read -p "Enter the size of mount point: " msize
        read -p "Enter the mount point name(/test): " mpt


        # Validate disk

        if [[ -b "/dev/$dsk" ]]
        then
                echo "Valid block device: /dev/$dsk"
        else
                echo "Not a valid disk"
                return 1
        fi


        # Create PV

        if pvs "/dev/$dsk" &>/dev/null
        then
                echo "Disk is already a Physical Volume"
                return 1
        fi

        if ! pvcreate "/dev/$dsk"
        then
                echo "PV creation failed"
                return 1
        fi


        # Create VG

        if vgdisplay "$vg" &>/dev/null
        then
                echo "VG already exists"
                return 1
        fi

        if ! vgcreate "$vg" "/dev/$dsk"
        then
                echo "VG creation failed"
                return 1
        fi


        # Create LV

        if lvdisplay "/dev/${vg}/${lv}" &>/dev/null
        then
                echo "LV already exists"
                return 1
        fi

        if ! lvcreate -L "$msize" -n "$lv" "$vg"
        then
                echo "LV creation failed"
                return 1
        fi


        # Create filesystem

        if ! mkfs -t "$fstype" "/dev/${vg}/${lv}"
        then
                echo "Filesystem creation failed"
                return 1
        fi


        # Mount point

        if [[ -d "$mpt" ]]
        then
                echo "Mount point already exists"
        else
                mkdir -p "$mpt" || return 1
        fi


        # fstab + mount

        if findmnt "$mpt" &>/dev/null
        then
                echo "Mount point is already mounted"
        else

                if grep -qE "[[:space:]]$mpt[[:space:]]" /etc/fstab
                then
                        echo "fstab entry already exists"
                else
                        echo "/dev/${vg}/${lv} $mpt $fstype defaults 0 0" >> /etc/fstab
                fi

                if mount "$mpt"
                then
                        echo "Filesystem mounted successfully"
                else
                        echo "Mount failed"
                        return 1
                fi
        fi
}


# ============================================================
# LVM EXTEND
# ============================================================

lvm_extend(){

        read -p "Enter the mount point which you want to extend(/test): " mpt
        read -p "Enter the size which you want for the mount point: " nsize


        # Validate mount point

        if ! findmnt "$mpt" &>/dev/null
        then
                echo "Mount point is not mounted"
                return 1
        fi


        # Find LV

        lmpt=$(findmnt "$mpt" -o SOURCE -n)

        if [[ -z "$lmpt" ]]
        then
                echo "Unable to find logical volume"
                return 1
        fi


        # Current size

        osize=$(df -hT "$mpt" | awk 'NR>1 {print $3}')

        old_bytes=$(numfmt --from=iec "$osize")
        new_bytes=$(numfmt --from=iec "${nsize}G")


        # Compare sizes

        if [[ "$new_bytes" -gt "$old_bytes" ]]
        then

                if lvextend -L "${nsize}G" "$lmpt" -r
                then
                        echo "Filesystem successfully extended to ${nsize}G"
                else
                        echo "LV extension failed"
                        return 1
                fi

        else
                echo "New size must be greater than current size"
                return 1
        fi


        # Validation

        if findmnt "$mpt" &>/dev/null
        then
                echo "Mount point validation successful"
        else
                echo "Mount point validation failed"
                return 1
        fi
}


# ============================================================
# STATIC IP CONFIGURATION
# ============================================================

configure_static(){

        read -p "Enter the interface name: " int
        read -p "Enter the IP which you want to add: " ip
        read -p "Enter the subnet: " snet


        interface_found=false

        for i in $(nmcli connection show | awk 'NR>1 {print $4}')
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


        if ! nmcli connection add \
                type ethernet \
                ifname "$int" \
                con-name "$int" \
                ipv4.address "${ip}/${snet}" \
                ipv4.method manual
        then
                echo "Connection creation failed"
                return 1
        fi


        if nmcli connection up "$int"
        then
                echo "Static IP configured successfully"
        else
                echo "Connection activation failed"
                return 1
        fi
}


# ============================================================
# SECONDARY IP CONFIGURATION
# ============================================================

add_secondary(){

        read -p "Enter the interface name: " int
        read -p "Enter the secondary IP: " ip
        read -p "Enter the subnet: " snet


        interface_found=false

        for i in $(nmcli connection show | awk 'NR>1 {print $4}')
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


        if ! nmcli connection modify "$int" \
                +ipv4.addresses "${ip}/${snet}"
        then
                echo "Secondary IP addition failed"
                return 1
        fi


        if nmcli connection up "$int"
        then
                echo "Secondary IP added successfully"
        else
                echo "Connection activation failed"
                return 1
        fi
}


# ============================================================
# NETWORK CONFIGURATION MENU
# ============================================================

network_config(){

        echo
        echo "========================================"
        echo "       NETWORK CONFIGURATION"
        echo "========================================"

        echo "1) Configure Static IP"
        echo "2) Add Secondary IP"
        echo "3) Back"

        read -p "Choose an option (1/2/3): " opt


        case "$opt" in

                1)
                        configure_static
                        ;;

                2)
                        add_secondary
                        ;;

                3)
                        return
                        ;;

                *)
                        echo "Invalid Option"
                        ;;

        esac
}


# ============================================================
# MAIN MENU
# ============================================================

echo
echo "========================================"
echo "       LINUX SERVER OPERATIONS"
echo "========================================"

echo "1) User / Group Provisioning"
echo "2) LVM Create"
echo "3) LVM Extend"
echo "4) Network Configuration"
echo "5) Exit"

read -p "Choose an option: " opt


case "$opt" in

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
                exit 0
                ;;

        *)
                echo "Invalid Option"
                ;;

esac
