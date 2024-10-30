getAllUsers() {
    awk -F: '$3 >= 1000 {print $1}' /etc/passwd | while read -r user; do
        if groups "$user" | grep -qE '\bsudo\b|\bwheel\b'; then
            echo "$user (Administrator)"
        else
            echo "$user"
        fi
    done
}