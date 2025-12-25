#!/bin/bash

LOG_FILE="/var/log/user_manager.log"

create_user() {
    read -p "Enter username: " user
    read -p "Enter role (admin/dev/test): " role

    case $role in
        admin) group="admins" ;;
        dev) group="developers" ;;
        test) group="testers" ;;
        *) echo "Invalid role"; return ;;
    esac

    if id "$user" &>/dev/null; then
        echo "User already exists" | tee -a $LOG_FILE
    else
        groupadd -f $group
        useradd -m -g $group $user
        echo "$user:Welcome@123" | chpasswd
        chage -M 30 $user
        mkdir -p /home/$user/work
        chown $user:$group /home/$user/work
        chmod 750 /home/$user/work
        echo "User $user created with role $role" | tee -a $LOG_FILE
    fi
}

lock_inactive_users() {
    for user in $(awk -F: '$3>=1000 {print $1}' /etc/passwd); do
        lastlog -b 30 -u $user | grep -q "Never logged in"
        if [ $? -eq 0 ]; then
            passwd -l $user
            echo "Locked inactive user: $user" >> $LOG_FILE
        fi
    done
}

delete_user() {
    read -p "Enter username to delete: " user
    userdel -r $user && echo "Deleted user $user" >> $LOG_FILE
}

while true; do
    echo "-----------------------------"
    echo "1. Create User"
    echo "2. Lock Inactive Users"
    echo "3. Delete User"
    echo "4. Exit"
    echo "-----------------------------"
    read -p "Choose option: " choice

    case $choice in
        1) create_user ;;
        2) lock_inactive_users ;;
        3) delete_user ;;
        4) exit ;;
        *) echo "Invalid option" ;;
    esac
done
