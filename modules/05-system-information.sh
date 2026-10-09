#!/bin/sh

# Read hostname, kernel, memory, uptime, load, and disk usage.
# Sets: SYSTEM_HOSTNAME, SYSTEM_KERNEL, SYSTEM_MEMORY, SYSTEM_UPTIME,
# SYSTEM_LOAD, SYSTEM_DISK. Disk lookup uses DATA_ROOT or /.
detect_system_information() {
    SYSTEM_HOSTNAME=$(uname -n 2>/dev/null) || SYSTEM_HOSTNAME=''
    SYSTEM_KERNEL=$(uname -r 2>/dev/null) || SYSTEM_KERNEL=''
    SYSTEM_MEMORY=$(awk '
        /^MemTotal:/ { total = $2 }
        /^MemAvailable:/ { available = $2; found = 1 }
        /^MemFree:/ { free = $2 }
        END {
            if (total > 0) {
                if (!found) available = free
                printf "%.0f / %.0f MiB (%.1f%% %s)", available / 1024,
                    total / 1024, available * 100 / total,
                    found ? "available" : "free"
            }
        }' /proc/meminfo 2>/dev/null) || SYSTEM_MEMORY=''
    SYSTEM_UPTIME=$(awk '{
        seconds = int($1)
        printf "%dd %dh %dm", int(seconds / 86400),
            int(seconds / 3600) % 24, int(seconds / 60) % 60
    }' /proc/uptime 2>/dev/null) || SYSTEM_UPTIME=''
    SYSTEM_LOAD=$(awk '{ printf "%s / %s / %s (1 / 5 / 15 min)", $1, $2, $3 }' \
        /proc/loadavg 2>/dev/null) || SYSTEM_LOAD=''
    SYSTEM_DISK=$(df -Pk "${DATA_ROOT:-/}" 2>/dev/null | awk '
        NR == 2 && $2 > 0 {
            printf "%.0f / %.0f MiB used (%s); %.0f MiB free",
                $3 / 1024, $2 / 1024, $5, $4 / 1024
        }')
}
