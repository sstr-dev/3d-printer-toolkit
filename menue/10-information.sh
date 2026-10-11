#!/bin/sh

show_project_information() (
    project_version=$(git -C "$PROJECT_ROOT" describe --tags --always --dirty 2>/dev/null) || project_version=''
    project_url=$(git -C "$PROJECT_ROOT" config --get remote.origin.url 2>/dev/null) || project_url=''

    system_line 'Version:' "${project_version:-Unavailable}"
    system_line 'URL:' "${project_url:-Unavailable}"
)

show_os_information() (
    detect_system_information

    system_line 'System:' "$OS_NAME"
    system_line 'Architecture:' "$ARCHITECTURE"
    system_line 'Hostname:' "${SYSTEM_HOSTNAME:-Unavailable}"
    system_line 'Kernel:' "${SYSTEM_KERNEL:-Unavailable}"
    system_line 'Uptime:' "${SYSTEM_UPTIME:-Unavailable}"
    system_line 'RAM:' "${SYSTEM_MEMORY:-Unavailable}"
    system_line 'Load average:' "${SYSTEM_LOAD:-Unavailable}"
    system_line 'Data disk:' "${SYSTEM_DISK:-Unavailable}"
)

show_printer_information() (
    detect_printer_information

    system_line 'Model:' "$PRINTER_MODEL"
    system_line 'Serial number:' "${PRINTER_SN:-Unavailable}"
    system_line 'Machine Serial number:' "${PRINTER_MACHINE_SN:-Unavailable}"
    system_line 'Firmware:' "${PRINTER_VERSION:-Unavailable}"
    system_line 'Mainboard:' "${PRINTER_BOARD:-Unavailable}"
    system_line 'IP addresses:' "${PRINTER_IPS:-Unavailable}"

    subtitle '•ESSENTIALS:'
    info_line "$(check_folder_menu "$MOONRAKER_FOLDER")" 'Moonraker & Nginx'
    info_line "$(check_folder_menu "$FLUIDD_FOLDER")" 'Fluidd'
    #info_line "$(check_folder_menu "$MAINSAIL_FOLDER")" 'Mainsail'
    hr
    subtitle '•UTILITIES:'
    info_line "$(check_file_menu "$ENTWARE_FILE")" 'Entware'
    info_line "$(check_file_menu "$KLIPPER_SHELL_FILE")" 'Klipper Gcode Shell Command'
    hr
    subtitle '•IMPROVEMENTS:'
    info_line "$(check_folder_menu "$KAMP_FOLDER")" 'Klipper Adaptive Meshing & Purging'
    info_line "$(check_file_menu "$BUZZER_FILE")" 'Buzzer Support'
    info_line "$(check_folder_menu "$NOZZLE_CLEANING_FOLDER")" 'Nozzle Cleaning Fan Control'
    info_line "$(check_file_menu "$FAN_CONTROLS_FILE")" 'Fans Control Macros' 
    info_line "$(check_folder_menu "$IMP_SHAPERS_FOLDER")" 'Improved Shapers Calibrations'
    info_line "$(check_file_menu "$USEFUL_MACROS_FILE")" 'Useful Macros'
    info_line "$(check_file_menu "$SAVE_ZOFFSET_FILE")" 'Save Z-Offset Macros'
    #info_line "$(check_file_menu "$SCREWS_ADJUST_FILE")" 'Screws Tilt Adjust Support'
    #info_line "$(check_file_menu "$M600_SUPPORT_FILE")" 'M600 Support'
    info_line "$(check_file_menu "$GIT_BACKUP_FILE")" 'Git Backup'
    hr
    subtitle '•CAMERA:'
    info_line "$(check_file_menu "$TIMELAPSE_FILE")" 'Moonraker Timelapse'
    info_line "$(check_file_menu "$CAMERA_SETTINGS_FILE")" 'Camera Settings Control'
    #info_line "$(check_file_menu "$USB_CAMERA_FILE")" 'USB Camera Support'
    hr
    subtitle '•REMOTE ACCESS:'
    #info_line "$(check_folder_menu "$OCTOEVERYWHERE_FOLDER")" 'OctoEverywhere'
    #info_line "$(check_folder_menu "$MOONRAKER_OBICO_FOLDER")" 'Obico'
    #info_line "$(check_folder_menu "$GUPPYFLO_FOLDER")" 'GuppyFLO'
    #info_line "$(check_folder_menu "$MOBILERAKER_COMPANION_FOLDER")" 'Mobileraker Companion'
    #info_line "$(check_folder_menu "$OCTOAPP_COMPANION_FOLDER")" 'OctoApp Companion'
    info_line "$(check_moonraker_component_menu "simplyprint")" 'SimplyPrint'
    hr
    subtitle '•CUSTOMIZATION:'
    #info_line "$(check_file_menu "$BOOT_DISPLAY_FILE")" 'Custom Boot Display'
    info_line "$(check_file_menu "$CREALITY_WEB_FILE")" 'Creality Web Interface'
    info_line "$(check_folder_menu "$GUPPY_SCREEN_FOLDER")" 'Guppy Screen'
    #info_line "$(check_file_menu "$FLUIDD_LOGO_FILE")" 'Creality Dynamic Logos for Fluidd'
    info_line "$(check_file_menu "$CLOUD_BLOCK_SERVICE_FILE")" 'Block Creality Cloud Telemetry'
    info_line "$(check_folder_menu "$EXTRA_MACROS_FOLDER")" 'Extra macros'
)

show_information() {
    top_line
    menu_line 'Printer' cyan
    inner_line
    show_printer_information
    inner_line
    menu_line 'OS' cyan
    inner_line
    show_os_information
    inner_line
    menu_line 'Project' cyan
    inner_line
    show_project_information
    outer_line
}

show_packages_information()
{
    # installed versions (moonraker, klipper, nginx, ...)
    # if check_file "$NGINX_CONF_FILE"; then
    #    # nginx
    # fi

    # list installed opkg packages
    #if check_file "$ENTWARE_FILE"; then
    #    #$ENTWARE_FILE list-installed
    #fi
}

register_action 'Show all Informations' show_information
register_action 'Show Printer Informations' show_printer_information
register_action 'Show OS Informations' show_os_information
register_action 'Show Project Informations' show_project_information
# register_action 'Show Package Informations' show_packages_information