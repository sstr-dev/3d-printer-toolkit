#!/bin/sh

# install / update
# ESSENTIALS
register_action "$(check_folder_action "$MOONRAKER_FOLDER")"'Moonraker & Nginx' "$S_ACTIONS/moonraker_nginx.sh" install 'K1C generic'

# UTILITIES
register_action "$(check_file_action "$ENTWARE_FILE")"'Entware' "$S_ACTIONS/entware.sh" install 'K1C K1_2025'

# IMPROVEMENTS


# remove
if check_folder "$MOONRAKER_FOLDER"; then
    register_action "$(check_folder_action "$MOONRAKER_FOLDER")"'Moonraker & Nginx' "$S_ACTIONS/moonraker_nginx.sh" remove 'K1C generic'
fi
if check_file "$ENTWARE_FILE"; then
    register_action "$(check_file_action "$ENTWARE_FILE")"'Entware' "$S_ACTIONS/entware.sh" remove 'K1C K1_2025'
fi





#info_line "$(check_folder_action "$MOONRAKER_FOLDER")" 'Moonraker & Nginx'
#info_line "$(check_folder_action "$FLUIDD_FOLDER")" 'Fluidd'
#info_line "$(check_folder_action "$MAINSAIL_FOLDER")" 'Mainsail'
#subtitle '•UTILITIES:'
#info_line "$(check_file_action "$ENTWARE_FILE")" 'Entware'
#info_line "$(check_file_action "$KLIPPER_SHELL_FILE")" 'Klipper Gcode Shell Command'
#subtitle '•IMPROVEMENTS:'
#info_line "$(check_folder_action "$KAMP_FOLDER")" 'Klipper Adaptive Meshing & Purging'
#info_line "$(check_file_action "$BUZZER_FILE")" 'Buzzer Support'
#info_line "$(check_folder_action "$NOZZLE_CLEANING_FOLDER")" 'Nozzle Cleaning Fan Control'
#info_line "$(check_file_action "$FAN_CONTROLS_FILE")" 'Fans Control Macros' 
#info_line "$(check_folder_action "$IMP_SHAPERS_FOLDER")" 'Improved Shapers Calibrations'
#info_line "$(check_file_action "$USEFUL_MACROS_FILE")" 'Useful Macros'
#info_line "$(check_file_action "$SAVE_ZOFFSET_FILE")" 'Save Z-Offset Macros'
#info_line "$(check_file_action "$SCREWS_ADJUST_FILE")" 'Screws Tilt Adjust Support'
#info_line "$(check_file_action "$M600_SUPPORT_FILE")" 'M600 Support'
#info_line "$(check_file_action "$GIT_BACKUP_FILE")" 'Git Backup'
#subtitle '•CAMERA:'
#info_line "$(check_file_action "$TIMELAPSE_FILE")" 'Moonraker Timelapse'
#info_line "$(check_file_action "$CAMERA_SETTINGS_FILE")" 'Camera Settings Control'
#info_line "$(check_file_menu "$USB_CAMERA_FILE")" 'USB Camera Support'
#subtitle '•REMOTE ACCESS:'
#info_line "$(check_folder_action "$OCTOEVERYWHERE_FOLDER")" 'OctoEverywhere'
#info_line "$(check_folder_action "$MOONRAKER_OBICO_FOLDER")" 'Obico'
#info_line "$(check_folder_action "$GUPPYFLO_FOLDER")" 'GuppyFLO'
#info_line "$(check_folder_action "$MOBILERAKER_COMPANION_FOLDER")" 'Mobileraker Companion'
#info_line "$(check_folder_action "$OCTOAPP_COMPANION_FOLDER")" 'OctoApp Companion'
#info_line "$(check_moonraker_component_action "simplyprint")" 'SimplyPrint'

