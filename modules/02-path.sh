#!/bin/sh

# Colors are available before the printer selection menu.
white=$(printf '\033[m')
blue=$(printf '\033[36m')
cyan=$(printf '\033[1;36m')
yellow=$(printf '\033[1;33m')
green=$(printf '\033[01;32m')
darkred=$(printf '\033[31m')
red=$(printf '\033[01;31m')
strikethrough=$(printf '\033[9m')

# Set printer paths from PRINTER_MODEL and optional path overrides.
# Sets: USR_DATA, USR_SHARE, INITD_FOLDER, BIN_FOLDER, PRINTER_DATA_FOLDER,
# PRINTER_DATA_CONFIG_FOLDER, PRINTER_DATA_LOG_FOLDER, S_FILES, S_ACTIONS.
# Creates project-local system directories for generic printers.
set_paths() {
    case "$PRINTER_MODEL" in
        K1C) 
            USR_DATA=${USR_DATA:-/usr/data} 
            USR_SHARE=${USR_SHARE:-/usr/share} 
            INITD_FOLDER=${INITD_FOLDER:-/etc/init.d} 
            BIN_FOLDER=${BIN_FOLDER:-/usr/bin} ;;
        K1_2025) 
            USR_DATA=${USR_DATA:-/usr/data}
            USR_SHARE=${USR_SHARE:-/usr/share}
            INITD_FOLDER=${INITD_FOLDER:-/usr/apps/etc/init.d}
            BIN_FOLDER=${BIN_FOLDER:-/usr/apps/usr/bin} ;;
        *) 
            USR_DATA=${USR_DATA:-"$PROJECT_ROOT/.local/usr/data"}
            USR_SHARE=${USR_SHARE:-"$PROJECT_ROOT/.local/usr/share"}
            INITD_FOLDER=${INITD_FOLDER:-"$PROJECT_ROOT/.local/etc/init.d"}
            BIN_FOLDER=${BIN_FOLDER:-"$PROJECT_ROOT/.local/usr/bin"} ;;
    esac

    PRINTER_DATA_FOLDER=${PRINTER_DATA_FOLDER:-"$USR_DATA/printer_data"}
    PRINTER_DATA_CONFIG_FOLDER=${PRINTER_DATA_CONFIG_FOLDER:-"$PRINTER_DATA_FOLDER/config"}
    PRINTER_DATA_LOG_FOLDER=${PRINTER_DATA_LOG_FOLDER:-"$PRINTER_DATA_FOLDER/logs"}

    # Configuration Files #
    MOONRAKER_CFG="${PRINTER_DATA_CONFIG_FOLDER}/moonraker.conf"
    PRINTER_CFG="${PRINTER_DATA_CONFIG_FOLDER}/printer.cfg"
    MACROS_CFG="${PRINTER_DATA_CONFIG_FOLDER}/gcode_macro.cfg"
  
    # Printer Script #
    S_FILES="${PROJECT_ROOT}/files"
    S_ACTIONS="${PROJECT_ROOT}/actions"

    # System #
    if [ "$PRINTER_MODEL" != "generic" ]; then
        CURL="${S_FILES}/fixes/curl"
    else
        CURL=$(command -v curl)
        for dir in "$USR_DATA" "$USR_SHARE" "$INITD_FOLDER" "$BIN_FOLDER"; do
            case "$dir" in
                "${PROJECT_ROOT%/}"/*)
                    [ -d "$dir" ] || mkdir -p -- "$dir"
                    ;;
            esac
        done
    fi

    # path per application..

    # Entware #
    #ENTWARE_FILE="/opt/bin/opkg"
    #ENTWARE_URL="${HS_FILES}/entware/generic.sh"
    #ENTWARE_OPT_MOUNT="${USR_DATA}/entware_opt_mount.img"

    # Moonraker #

    # Klipper #




    #APPLICATIONS_DIR=${APPLICATIONS_DIR:-"$DATA_ROOT"}

}

# Make CURL executable in the background when its path is configured.
# Background failures are not reported to the caller.
set_permissions() {
    if [ "$PRINTER_MODEL" != "generic" ]; then
        if [ -n "$CURL" ]; then
            chmod +x "$CURL" >/dev/null 2>&1 &
        fi
    fi
}

check_folder() {
  [ -d "$1" ]
}

check_file() {
  [ -f "$1" ]
}

check_moonraker_component() {
  [ -n "${1:-}" ] && [ -r "$MOONRAKER_CFG" ] || return 1
  grep -Fq "[$1]" "$MOONRAKER_CFG"
}


