#!/bin/bash

report_file="report.txt"

listAllUsers() {
    awk -F: '$3 >= 1000 {print $1}' /etc/passwd | while read -r user; do
        if groups "$user" | grep -qE '\bsudo\b|\bwheel\b'; then
            echo "$user (Administrator)"
        else
            echo "$user"
        fi
    done >> "$report_file"
}

checkUnnecessaryFiles() {
    awk -F: '$3 >= 1000 {print $1, $6}' /etc/passwd | while read -r user home_dir; do
        echo "Checking for unnecessary files in $user's home directory: $home_dir" >> "$report_file"
        
        find "$home_dir" -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.png" -o -name "*.jpg" \) ! -path "*/.*" -print >> "$report_file"
    done
}

listPackages() {
    dpkg-query -W -f='${binary:Package} : ${binary:Summary}\n' >> "$report_file"
}

listServices() {
    systemctl list-units --type=service --state=loaded --no-pager --no-legend | awk '{print $1}' | while read -r service; do
        description=$(systemctl show -p Description --value "$service")
        echo "$service : $description" >> "$report_file"
    done
}

listPrograms() {
    dpkg-query -W -f='${binary:Package} : ${binary:Summary}\n' | grep -v -E 'linux-image|^lib|^gnome|^kde|^systemd|^apt|^dpkg|^base|^debian|^firmware' >> "$report_file"
}



while [[ true ]]; do
    sudo -v

    echo "Choose your option:"
    echo "1. List all Users"
    echo "2. Check for unnecessary files"
    echo "3. List packages"
    echo "4. List services"
    echo "5. List programs"
    echo "6. Exit"
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
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option."
    esac 
done