getAllUsers() {
    awk -F: '$3 >= 1000 {print $1}' /etc/passwd | while read -r user; do
        if groups "$user" | grep -qE '\bsudo\b|\bwheel\b'; then
            echo "$user (Administrator)"
        else
            echo "$user"
        fi
    done
}

checkUnnecessaryFiles() {
    awk -F: '$3 >= 1000 {print $1, $6}' /etc/passwd | while read -r user home_dir; do
        echo "Checking for unnecessary files in $user's home directory: $home_dir"
        
        find "$home_dir" -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.png" -o -name "*.jpg" \) ! -path "*/.*" -print
    done
}

listPackages() {
    dpkg-query -W -f='${binary:Package} : ${binary:Summary}\n'
}

listServices() {
    systemctl list-units --type=service --state=loaded --no-pager --no-legend | awk '{print $1}' | while read -r service; do
        description=$(systemctl show -p Description --value "$service")
        echo "$service : $description"
    done
}

listPrograms() {
    dpkg-query -W -f='${binary:Package} : ${binary:Summary}\n' | grep -v -E 'linux-image|^lib|^gnome|^kde|^systemd|^apt|^dpkg|^base|^debian|^firmware'
}