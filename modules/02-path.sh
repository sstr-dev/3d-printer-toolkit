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
    S_CONFIG_FOLDER="$PRINTER_DATA_FOLDER/config/3dp-toolkit"
    S_BACKUP_FOLDER="$USR_DATA/3dp-toolkit-backup"

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

    # Application paths.

    # Entware #
    ENTWARE_FILE="/opt/bin/opkg"
    ENTWARE_URL="${S_FILES}/entware/generic.sh"
    ENTWARE_OPT_MOUNT="${USR_DATA}/entware_opt_mount.img"

    # Moonraker #
    MOONRAKER_FOLDER="${USR_DATA}/moonraker"
    MOONRAKER_ENV_PYTHON="${MOONRAKER_FOLDER}/moonraker-env/bin/python3"
    MOONRAKER_URL1="${S_FILES}/moonraker/moonraker.tar.gz"
    MOONRAKER_URL2="${S_FILES}/moonraker/moonraker.conf"
    MOONRAKER_URL3="${S_FILES}/moonraker/moonraker.asvc"
    MOONRAKER_SERVICE_URL="${S_FILES}/services/S56moonraker_service"

    # Nginx #
    NGINX_FOLDER="${USR_DATA}/nginx"
    NGINX_BIN="${NGINX_FOLDER}/sbin/nginx"
    NGINX_CONF_FILE="${NGINX_FOLDER}/nginx/nginx.conf"
    NGINX_URL="${S_FILES}/moonraker/nginx.tar.gz"
    NGINX_SERVICE_URL="${S_FILES}/services/S50nginx"
    NGINX_CONF_URL="${S_FILES}/moonraker/nginx.conf"

    # Supervisor Lite #
    SUPERVISOR_FILE="$BIN_FOLDER/supervisorctl"
    SUPERVISOR_OPT_FILE="/opt/bin/supervisorctl"
    SUPERVISOR_URL="${S_FILES}/fixes/supervisorctl"

    # Host Controls Support #
    SYSTEMCTL_FILE="$BIN_FOLDER/systemctl"
    SYSTEMCTL_URL="${S_FILES}/fixes/systemctl"
    SUDO_FILE="$BIN_FOLDER/sudo"
    SUDO_URL="${S_FILES}/fixes/sudo"

    # Klipper #
    KLIPPER_EXTRAS_FOLDER="/usr/share/klipper/klippy/extras"
    KLIPPER_CONFIG_FOLDER="${PRINTER_DATA_FOLDER}/config"
    KLIPPER_KLIPPY_FOLDER="/usr/share/klipper/klippy"
    if [ "$PRINTER_MODEL" = "K1_2025" ]; then
        KLIPPER_SERVICE_URL="${S_FILES}/services/CS55klipper_service_minimal"
    else
        KLIPPER_SERVICE_URL="${S_FILES}/services/S55klipper_service"
    fi
    KLIPPER_GCODE_URL="${S_FILES}/fixes/gcode.py"
    KLIPPER_GCODE_3V3_URL="${S_FILES}/fixes/gcode_3v3.py"

    # Klipper Gcode Shell Command #
    KLIPPER_SHELL_FILE="${KLIPPER_EXTRAS_FOLDER}/gcode_shell_command.py"
    KLIPPER_SHELL_URL="${S_FILES}/gcode-shell-command/gcode_shell_command.py"

    # Extended Gcode Params #
    EXTENDED_GCODE_PARAMS_FILE="${KLIPPER_EXTRAS_FOLDER}/extended_gcode_params.py"
    EXTENDED_GCODE_PARAMS_URL="${S_FILES}/extended-gcode-params/extended_gcode_params.py"

    # Klipper Adaptive Meshing & Purging #
    KAMP_FOLDER="${S_CONFIG_FOLDER}/KAMP"
    KAMP_URL="${S_FILES}/kamp"
    VIRTUAL_PINS_FILE="${KLIPPER_EXTRAS_FOLDER}/virtual_pins.py"
    VIRTUAL_PINS_URL="${S_FILES}/klipper-virtual-pins/virtual_pins.py"

    # Buzzer Support #
    BUZZER_FILE="${S_CONFIG_FOLDER}/buzzer-support.cfg"
    BUZZER_URL="${S_FILES}/buzzer-support/buzzer-support.cfg"
    
    # Nozzle Cleaning Fan Control #
    NOZZLE_CLEANING_FOLDER="${KLIPPER_EXTRAS_FOLDER}/prtouch_v2_fan"
    NOZZLE_CLEANING_URL1="${S_FILES}/nozzle-cleaning-fan-control/__init__.py"
    NOZZLE_CLEANING_URL2="${S_FILES}/nozzle-cleaning-fan-control/prtouch_v2_fan.pyc"
    NOZZLE_CLEANING_URL3="${S_FILES}/nozzle-cleaning-fan-control/nozzle-cleaning-fan-control.cfg"
    
    # Fans Control Macros #
    FAN_CONTROLS_FILE="${S_CONFIG_FOLDER}/fans-control.cfg"
    FAN_CONTROLS_URL="${S_FILES}/macros/fans-control.cfg"
    
    # Improved Shapers Calibrations #
    IMP_SHAPERS_FOLDER="${S_CONFIG_FOLDER}/improved-shapers"
    IMP_SHAPERS_URL="${S_FILES}/improved-shapers"

    # Restore Input Shapers (K1C 2025) #
    RESTORE_SHAPERS_URL="${S_FILES}/restore-input-shapers/shaper_defs.py"
    SHAPER_DEFS_FILE="${KLIPPER_EXTRAS_FOLDER}/shaper_defs.py"


    # Useful Macros #
    USEFUL_MACROS_FILE="${S_CONFIG_FOLDER}/useful-macros.cfg"
    USEFUL_MACROS_URL="${S_FILES}/macros/useful-macros.cfg"
    USEFUL_MACROS_3V3_URL="${S_FILES}/macros/useful-macros-3v3.cfg"

    # M600 Support #
    M600_SUPPORT_FILE="${S_CONFIG_FOLDER}/M600-support.cfg"
    M600_SUPPORT_URL="${S_FILES}/macros/M600-support.cfg"
    M600_SUPPORT_3V3_URL="${S_FILES}/macros/M600-support-3v3.cfg"
    M600_SUPPORT_3KE_URL="${S_FILES}/macros/M600-support-ke.cfg"
    
    # Git Backup #
    GIT_BACKUP_INSTALLER="${S_FILES}/git-backup/git-backup.sh"
    GIT_BACKUP_FILE="${S_CONFIG_FOLDER}/git-backup.cfg"
    GIT_BACKUP_URL="${S_FILES}/git-backup/git-backup.cfg"
    
    # Moonraker Timelapse #
    TIMELAPSE_FILE="${USR_DATA}/moonraker/moonraker/moonraker/components/timelapse.py"
    TIMELAPSE_URL1="${S_FILES}/moonraker-timelapse/timelapse.py"
    TIMELAPSE_URL2="${S_FILES}/moonraker-timelapse/timelapse.cfg"
    
    # Camera Settings Control #
    CAMERA_SETTINGS_FILE="${S_CONFIG_FOLDER}/camera-settings.cfg"
    CAMERA_SETTINGS_URL="${S_FILES}/camera-settings/camera-settings.cfg"
    CAMERA_SETTINGS_NEBULA_URL="${S_FILES}/camera-settings/camera-settings-nebula.cfg"
    CAMERA_SETTINGS_K1_2025_URL="${S_FILES}/camera-settings/camera-settings-k1c-2025.cfg"

    # Creality Web Interface #
    CREALITY_WEB_FILE="${BIN_FOLDER}/web-server"

    # Creality Stock Services (K1C 2025) #
    # INITD_FOLDER is already model-branched above; these files only exist on the
    # K1_2025, and the option using them is only reachable from its Customize menu.
    CREALITY_TELEMETRY_SERVICE="${INITD_FOLDER}/CS61alchemistp_service"
    CREALITY_CLOUD_WEBRTC_SERVICE="${INITD_FOLDER}/CS58onyxp_service"
    CREALITY_LOCAL_WEBRTC_SERVICE="${INITD_FOLDER}/CS59thirteenthp"
    CREALITY_AI_SERVICE="${INITD_FOLDER}/CS57solusp_service"
    CREALITY_MDNS_SERVICE="${INITD_FOLDER}/CS99mdns"

    # Block Creality Cloud Telemetry #
    CLOUD_BLOCK_SERVICE_URL="${S_FILES}/services/S995cloudblock"
    CLOUD_BLOCK_SERVICE_FILE="${INITD_FOLDER}/S995cloudblock"
    #APPLICATIONS_DIR=${APPLICATIONS_DIR:-"$DATA_ROOT"}

    # Guppy Screen #
    GUPPY_SCREEN_FOLDER="${USR_DATA}/guppyscreen"
    GUPPY_SCREEN_URL1="${S_FILES}/guppy-screen/guppy_update.cfg"
    GUPPY_SCREEN_URL2="${S_FILES}/guppy-screen/guppy-update.sh"
    GUPPY_SCREEN_3V3_URL="${S_FILES}/guppy-screen/guppy_update-3v3.cfg"
    GUPPY_SCREEN_CONFIG_3V3_URL="${S_FILES}/guppy-screen/guppyconfig-3v3.json"

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
    grep -q "^\[$1\]" "$MOONRAKER_CFG"
}

# check_printer_component "output_pin LED"
check_printer_component() {
    [ -n "${1:-}" ] && [ -r "$PRINTER_CFG" ] || return 1
    grep -q "^\[$1\]" "$PRINTER_CFG"
}
