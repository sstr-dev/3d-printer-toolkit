#!/bin/sh

# Read available printer details for PRINTER_MODEL.
# Sets: PRINTER_SN, PRINTER_VERSION, PRINTER_IPS; missing details stay empty.
detect_printer_information() {
    PRINTER_SN=''
    PRINTER_VERSION=''
    case "$PRINTER_MODEL" in
        K1|K1C)
            PRINTER_SN=$(sed -n 's/.*"device_sn"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
                /usr/data/creality/userdata/config/system_config.json 2>/dev/null) || PRINTER_SN=''
            PRINTER_VERSION=$(sed -n 's/.*"sys_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
                /usr/data/creality/userdata/config/system_version.json 2>/dev/null) || PRINTER_VERSION=''
            ;;
        K1_2025)
            if command -v get_sn_mac.sh >/dev/null 2>&1; then
                PRINTER_SN=$(get_sn_mac.sh sn 2>/dev/null) || PRINTER_SN=''
            fi
            if [ -r /etc/version ]; then
                PRINTER_VERSION=$(cat /etc/version 2>/dev/null) || PRINTER_VERSION=''
            fi
            ;;
        generic)
            for serial_file in /proc/device-tree/serial-number /sys/class/dmi/id/product_serial; do
                [ -r "$serial_file" ] || continue
                PRINTER_SN=$(tr -d '\000\r\n' < "$serial_file" 2>/dev/null)
                [ -z "$PRINTER_SN" ] || break
            done
            ;;
    esac

    PRINTER_IPS=''
    if command -v ip >/dev/null 2>&1; then
        PRINTER_IPS=$(ip -o -4 addr show scope global 2>/dev/null |
            awk '{ sub(/\/.*/, "", $4); printf "%s%s (%s)", sep, $4, $2; sep=", " }')
    fi
    if [ -z "$PRINTER_IPS" ]; then
        PRINTER_IPS=$(hostname -I 2>/dev/null) || PRINTER_IPS=''
    fi
}
