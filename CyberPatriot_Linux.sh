#!/bin/bash

report_file="report.txt"

listAllUsers() {
    sudo awk -F: '$3 >= 1000 {print $1}' /etc/passwd | while read -r user; do
        if groups "$user" | grep -qE '\bsudo\b|\bwheel\b'; then
            echo "$user (Administrator)"
        else
            echo "$user"
        fi
    done >> "$report_file"
}

checkUnnecessaryFiles() {
    sudo awk -F: '$3 >= 1000 {print $1, $6}' /etc/passwd | while read -r user home_dir; do
        echo "Checking for unnecessary files in $user's home directory: $home_dir" >> "$report_file"
        
        if [ -d "$home_dir" ]; then
            sudo find "$home_dir" -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.png" -o -name "*.jpg" \) ! -path "*/.*" -print >> "$report_file"
        else
            echo "Directory $home_dir does not exist, skipping." >> "$report_file"
        fi
    done
}

listPackages() {
    sudo dpkg-query -W -f='${binary:Package} : ${binary:Summary}\n' >> "$report_file"
}

listServices() {
    sudo systemctl list-units --type=service --state=running --no-pager --no-legend | awk '{print $1}' | while read -r service; do
        description=$(systemctl show -p Description --value "$service")
        echo "$service : $description" >> "$report_file"
    done
}

listPrograms() {
    sudo dpkg-query -W -f='${binary:Package} : ${binary:Summary}\n' | grep -v -E 'linux-image|^lib|^gnome|^kde|^systemd|^apt|^dpkg|^base|^debian|^firmware' >> "$report_file"
}

checkEmptyPasswords() {
    sudo awk -F: '($3 >= 1000) && ($2 == "") {print $1}' /etc/shadow | while read -r user; do
    echo "$user" >> "$report_file"
    done
}

updatePackages()
{
    sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y
}

lockRoot()
{
    sudo passwd -l root

    if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
        sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    else
        echo "PermitRootLogin no" | sudo tee -a /etc/ssh/sshd_config
    fi

    sudo systemctl restart sshd
}

setPasswordPolicies()
{
    MIN_LENGTH=12
    MIN_DAYS=1
    MAX_DAYS=90
    WARN_DAYS=7
    REMEMBER=5
    MAX_RETRIES=3
    UNLOCK_TIME=300

    sudo sed -i "s/^PASS_MAX_DAYS.*/PASS_MAX_DAYS    $MAX_DAYS/" /etc/login.defs
    sudo sed -i "s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS    $MIN_DAYS/" /etc/login.defs
    sudo sed -i "s/^PASS_WARN_AGE.*/PASS_WARN_AGE    $WARN_DAYS/" /etc/login.defs

    sudo sed -i "/pam_pwquality.so/ s/$/ minlen=$MIN_LENGTH/" /etc/pam.d/common-password
    sudo sed -i "/pam_unix.so/ s/$/ remember=$REMEMBER/" /etc/pam.d/common-password
}

while [[ true ]]; do
    sudo -v

    echo "Choose your option:"
    echo "1. List all Users"
    echo "2. Check for unnecessary files"
    echo "3. List packages"
    echo "4. List services"
    echo "5. List programs"
    echo "6. Check for empty passwords"
    echo "7. Update packages"
    echo "8. Lock root account"
    echo "9. Update password policies"
    echo "10. Exit"
    echo ""
    read -p "Enter your choice: " choice

    case $choice in
        1)
            listAllUsers
            echo "Listed all users in "$report_file""
            ;;
        2)
            checkUnnecessaryFiles
            echo "Checked for unnecessary files in "$report_file""
            ;;
        3)
            listPackages
            echo "Listed all packages in "$report_file""
            ;;
        4)
            listServices
            echo "Listed all running services in "$report_file""
            ;;
        5)
            listPrograms
            echo "Listed all programs in "$report_file""
            ;;
        6)
            checkEmptyPasswords
            echo "Listed users with empty passwords in "$report_file""
            ;;
        7)
            updatePackages
            echo "Updated all packages"
            ;;
        8)
            lockRoot
            echo "Locked root account"
            ;;
        9)
            setPasswordPolicies
            echo "Updated Password Policies"
            ;;
        10)
            echo "Exiting..."
            exit 0
            ;;
        11)
            #Add the critical services into whitelist.txt.
            echo "This feature is still a work-in-progress."
        *)
            echo "Invalid option."
    esac 
done
