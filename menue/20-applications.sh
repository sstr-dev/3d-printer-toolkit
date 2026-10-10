#!/bin/sh


# function space
setup_gcode_shell_command()
{
    local yn installed=0
    if check_file "$KLIPPER_SHELL_FILE"; then
        installed=1
    fi
    while true; do
        if [ "$installed" = 1 ]; then
            remove_msg "Klipper Gcode Shell Command" yn || return 1
        else
            install_msg "Klipper Gcode Shell Command" yn || return 1
        fi
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                if [ "$installed" = 1 ]; then
                    echo -e "Info: Removing files..."
                    rm -f "$KLIPPER_EXTRAS_FOLDER"/gcode_shell_command.py
                    rm -f "$KLIPPER_EXTRAS_FOLDER"/gcode_shell_command.pyc
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Klipper Gcode Shell Command has been removed successfully!"
                else
                    echo -e "Info: Linking file..."
                    ln -sf "$KLIPPER_SHELL_URL" "$KLIPPER_EXTRAS_FOLDER"/gcode_shell_command.py
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    # Verify with the Klipper API method "gcode/help" (RUN_SHELL_COMMAND will be
                    # listed) — Creality's Klipper does NOT surface gcode_shell_command via
                    # "objects/list", so the extra can look like it failed to load when it works.
                    ok_msg "Klipper Gcode Shell Command has been installed successfully!"
                fi
                return 0
                ;;
            N|n)
                return 0
                ;;
            *)
                error_msg "Please select a correct choice!"
                ;;
        esac
    done
}

setup_buzzer_support()
{
    if [ ! -f "$KLIPPER_SHELL_FILE" ]; then
        error_msg "Klipper Gcode Shell Command is needed, please install it first!"
    else
        local yn installed=0
        if check_file "$BUZZER_FILE"; then
            installed=1
        fi
        while true; do
            if [ "$installed" = 1 ]; then
                remove_msg "Buzzer Support" yn || return 1
            else
                install_msg "Buzzer Support" yn || return 1
            fi
            case "${yn}" in
                Y|y)
                    echo -e "${white}"
                    if [ "$installed" = 1 ]; then

                        echo -e "Info: Removing file..."
                        rm -f "$S_CONFIG_FOLDER"/buzzer-support.cfg
                        if grep -q "include 3dp-toolkit/buzzer-support" "$PRINTER_CFG" ; then
                            echo -e "Info: Removing Buzzer Support configurations in printer.cfg file..."
                            sed -i '/include 3dp-toolkit\/buzzer-support\.cfg/d' "$PRINTER_CFG"
                        else
                            echo -e "Info: Buzzer Support configurations are already removed in printer.cfg file..."
                        fi
                        if [ ! -n "$(ls -A "$S_CONFIG_FOLDER")" ]; then
                            rm -rf "$S_CONFIG_FOLDER"
                        fi
                        echo -e "Info: Restarting Klipper service..."
                        restart_klipper
                        ok_msg "Buzzer Support has been removed successfully!"
                    else
                        if [ -f "$S_CONFIG_FOLDER"/buzzer-support.cfg ]; then
                            rm -f "$S_CONFIG_FOLDER"/buzzer-support.cfg
                        fi
                        if [ ! -d "$S_CONFIG_FOLDER" ]; then
                            mkdir -p "$S_CONFIG_FOLDER"
                        fi
                        echo -e "Info: Linking file..."
                        ln -sf "$BUZZER_URL" "$S_CONFIG_FOLDER"/buzzer-support.cfg
                        if grep -q "include 3dp-toolkit/buzzer-support" "$PRINTER_CFG" ; then
                            echo -e "Info: Buzzer Support configurations are already enabled in printer.cfg file..."
                        else
                            echo -e "Info: Adding Buzzer Support configurations in printer.cfg file..."
                            sed -i '/\[include printer_params\.cfg\]/a \[include 3dp-toolkit/buzzer-support\.cfg\]' "$PRINTER_CFG"
                        fi
                        echo -e "Info: Restarting Klipper service..."
                        restart_klipper
                        ok_msg "Buzzer Support has been installed successfully!"
                        echo -e "   You can now use ${yellow}BEEP ${white}command in your macros to play sound."
                    fi
                    return 0
                    ;;
                N|n)
                    return 0
                    ;;
                *)
                    error_msg "Please select a correct choice!"
                    ;;
            esac
        done
    fi
}

setup_fans_control_macros() 
{
    local yn installed=0
    if check_file "$FAN_CONTROLS_FILE"; then
        installed=1
    fi
    while true; do
        if [ "$installed" = 1 ]; then
            remove_msg "Fans Control Macros" yn || return 1
        else
            install_msg "Fans Control Macros" yn || return 1
        fi
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                if [ "$installed" = 1 ]; then
                    echo -e "Info: Removing file..."
                    rm -f "$S_CONFIG_FOLDER"/fans-control.cfg
                    if grep -q "include 3dp-toolkit/fans-control" "$PRINTER_CFG" ; then
                        echo -e "Info: Removing Fans Control Macros configurations in printer.cfg file..."
                        sed -i '/include 3dp-toolkit\/fans-control\.cfg/d' "$PRINTER_CFG"
                    else
                        echo -e "Info: Fans Control Macros configurations are already removed in printer.cfg file..."
                    fi
                    if grep -q "#\[duplicate_pin_override\]" "$PRINTER_CFG" ; then
                        echo -e "Info: Enabling [duplicate_pin_override] in printer.cfg file..."
                        sed -i -e 's/^\s*#[[:space:]]*\[duplicate_pin_override\]/[duplicate_pin_override]/' -e '/^\[duplicate_pin_override\]/,/^\s*$/ s/^\(\s*\)#/\1/' "$PRINTER_CFG"
                    else
                        echo -e "Info: [duplicate_pin_override] is already enabled in printer.cfg file..."
                    fi
                    if grep -q "#\[temperature_fan chamber_fan\]" "$PRINTER_CFG" ; then
                        echo -e "Info: Enabling [temperature_fan chamber_fan] in printer.cfg file..."
                        sed -i -e 's/^\s*#[[:space:]]*\[temperature_fan chamber_fan\]/[temperature_fan chamber_fan]/' -e '/^\[temperature_fan chamber_fan\]/,/^\s*$/ s/^\(\s*\)#/\1/' "$PRINTER_CFG"
                    else
                        echo -e "Info: [temperature_fan chamber_fan] is already enabled in printer.cfg file..."
                    fi
                    if grep -q "#\[gcode_macro M106\]" "$MACROS_CFG" ; then
                        echo -e "Info: Enabling [gcode_macro M106] in gcode_macro.cfg file..."
                        sed -i -e 's/^\s*#[[:space:]]*\[gcode_macro M106\]/[gcode_macro M106]/' -e '/^\[gcode_macro M106\]/,/^\s*$/ s/^\(\s*\)#/\1/' "$MACROS_CFG"
                    else
                        echo -e "Info: [gcode_macro M106] is already enabled in gcode_macro.cfg file..."
                    fi
                    if grep -q "#\[gcode_macro M141\]" "$MACROS_CFG" ; then
                        echo -e "Info: Enabling [gcode_macro M141] in gcode_macro.cfg file..."
                        sed -i -e 's/^\s*#[[:space:]]*\[gcode_macro M141\]/[gcode_macro M141]/' -e '/^\[gcode_macro M141\]/,/^\s*$/ s/^\(\s*\)#/\1/' "$MACROS_CFG"
                    else
                        echo -e "Info: [gcode_macro M141] is already enabled in gcode_macro.cfg file..."
                    fi
                    if [ ! -n "$(ls -A "$S_CONFIG_FOLDER")" ]; then
                        rm -rf "$S_CONFIG_FOLDER"
                    fi
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Fans Control Macros have been removed successfully!"
                else
                    if [ -f "$S_CONFIG_FOLDER"/fans-control.cfg ]; then
                        rm -f "$S_CONFIG_FOLDER"/fans-control.cfg
                    fi
                    if [ ! -d "$S_CONFIG_FOLDER" ]; then
                        mkdir -p "$S_CONFIG_FOLDER"
                    fi
                    echo -e "Info: Linking file..."
                    ln -sf "$FAN_CONTROLS_URL" "$S_CONFIG_FOLDER"/fans-control.cfg
                    if grep -q "include 3dp-toolkit/fans-control" "$PRINTER_CFG" ; then
                        echo -e "Info: Fans Control Macros configurations are already enabled in printer.cfg file..."
                    else
                        echo -e "Info: Adding Fans Control Macros configurations in printer.cfg file..."
                        sed -i '/\[include printer_params\.cfg\]/a \[include 3dp-toolkit/fans-control\.cfg\]' "$PRINTER_CFG"
                    fi
                    if grep -q "\[duplicate_pin_override\]" "$PRINTER_CFG" ; then
                        echo -e "Info: Disabling [duplicate_pin_override] configuration in printer.cfg file..."
                        sed -i '/^\[duplicate_pin_override\]/,/^\s*$/ s/^\(\s*\)\([^#]\)/#\1\2/' "$PRINTER_CFG"
                    else
                        echo -e "Info: [duplicate_pin_override] configuration is already disabled in printer.cfg file..."
                    fi
                    if grep -q "\[temperature_fan chamber_fan\]" "$PRINTER_CFG" ; then
                        echo -e "Info: Disabling [temperature_fan chamber_fan] configuration in printer.cfg file..."
                        sed -i '/^\[temperature_fan chamber_fan\]/,/^\s*$/ s/^\(\s*\)\([^#]\)/#\1\2/' "$PRINTER_CFG"
                    else
                        echo -e "Info: [temperature_fan chamber_fan] configuration is already disabled in printer.cfg file..."
                    fi
                    if grep -q "\[gcode_macro M106\]" "$MACROS_CFG" ; then
                        echo -e "Info: Disabling [gcode_macro M106] in gcode_macro.cfg file..."
                        sed -i '/^\[gcode_macro M106\]/,/^\s*$/ s/^\(\s*\)\([^#]\)/#\1\2/' "$MACROS_CFG"
                    else
                        echo -e "Info: [gcode_macro M106] macro is already disabled in gcode_macro.cfg file..."
                    fi
                    if grep -q "\[gcode_macro M141\]" "$MACROS_CFG" ; then
                        echo -e "Info: Disabling [gcode_macro M141] in gcode_macro.cfg file..."
                        sed -i '/^\[gcode_macro M141\]/,/^\s*$/ s/^\(\s*\)\([^#]\)/#\1\2/' "$MACROS_CFG"
                    else
                        echo -e "Info: [gcode_macro M141] macro is already disabled in gcode_macro.cfg file..."
                    fi
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Fans Control Macros have been installed successfully!"
                fi
                return 0
                ;;
            N|n)
                return 0
                ;;
            *)
                error_msg "Please select a correct choice!"
                ;;
        esac
    done
}

setup_nozzle_cleaning_fan_control() 
{
    local yn installed=0
    if check_folder "$NOZZLE_CLEANING_FOLDER"; then
        installed=1
    fi
    while true; do
        if [ "$installed" = 1 ]; then
            remove_msg "Nozzle Cleaning Fan Control" yn || return 1
        else
            install_msg "Nozzle Cleaning Fan Control" yn || return 1
        fi
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                if [ "$installed" = 1 ]; then
                    echo -e "Info: Removing files..."
                    rm -rf "$NOZZLE_CLEANING_FOLDER" 
                    rm -f "$S_CONFIG_FOLDER"/nozzle-cleaning-fan-control.cfg
                    if grep -q "include 3dp-toolkit/nozzle-cleaning-fan-control" "$PRINTER_CFG" ; then
                        echo -e "Info: Removing Nozzle Cleaning Fan Control configurations in printer.cfg file..."
                        sed -i '/include 3dp-toolkit\/nozzle-cleaning-fan-control\.cfg/d' "$PRINTER_CFG"
                    else
                        echo -e "Info: Nozzle Cleaning Fan Control configurations are already removed in printer.cfg file..."
                    fi
                    if [ ! -n "$(ls -A "$S_CONFIG_FOLDER")" ]; then
                        rm -rf "$S_CONFIG_FOLDER"
                    fi
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Nozzle Cleaning Fan Control has been removed successfully!"
                else
                    if [ -d "$NOZZLE_CLEANING_FOLDER" ]; then
                        rm -rf "$NOZZLE_CLEANING_FOLDER"
                    fi
                    mkdir -p "$NOZZLE_CLEANING_FOLDER"
                    echo -e "Info: Linking files..."
                    ln -sf "$NOZZLE_CLEANING_URL1" "$NOZZLE_CLEANING_FOLDER"/__init__.py
                    ln -sf "$NOZZLE_CLEANING_URL2" "$NOZZLE_CLEANING_FOLDER"/prtouch_v2_fan.pyc
                    if [ ! -d "$S_CONFIG_FOLDER" ]; then
                        mkdir -p "$S_CONFIG_FOLDER"
                    fi
                    ln -sf "$NOZZLE_CLEANING_URL3" "$S_CONFIG_FOLDER"/nozzle-cleaning-fan-control.cfg
                    if grep -q "include 3dp-toolkit/nozzle-cleaning-fan-control" "$PRINTER_CFG" ; then
                        echo -e "Info: Nozzle Cleaning Fan Control configurations are already enabled in printer.cfg file..."
                    else
                        echo -e "Info: Adding Nozzle Cleaning Fan Control configurations in printer.cfg file..."
                        sed -i '/\[include printer_params\.cfg\]/a \[include 3dp-toolkit/nozzle-cleaning-fan-control\.cfg\]' "$PRINTER_CFG"
                    fi
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Nozzle Cleaning Fan Control has been installed successfully!"
                fi
                return 0
                ;;
            N|n)
                return 0
                ;;
            *)
                error_msg "Please select a correct choice!"
                ;;
        esac
    done
}

setup_useful_macros()
{
    local yn installed=0
    if check_file "$USEFUL_MACROS_FILE"; then
        installed=1
    fi
    while true; do
        if [ "$installed" = 1 ]; then
            remove_msg "Useful Macros" yn || return 1
        else
            install_msg "Useful Macros" yn || return 1
        fi
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                if [ "$installed" = 1 ]; then
                    echo -e "Info: Removing file..."
                    rm -f "$S_CONFIG_FOLDER"/useful-macros.cfg
                    if grep -q "include 3dp-toolkit/useful-macros" "$PRINTER_CFG" ; then
                        echo -e "Info: Removing Useful Macros configurations in printer.cfg file..."
                        sed -i '/include 3dp-toolkit\/useful-macros\.cfg/d' "$PRINTER_CFG"
                    else
                        echo -e "Info: Useful Macros configurations are already removed in printer.cfg file..."
                    fi
                    if [ ! -n "$(ls -A "$S_CONFIG_FOLDER")" ]; then
                        rm -rf "$S_CONFIG_FOLDER"
                    fi
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Useful Macros have been removed successfully!"
                else
                    if [ -f "$S_CONFIG_FOLDER"/useful-macros.cfg ]; then
                        rm -f "$S_CONFIG_FOLDER"/useful-macros.cfg
                    fi
                    if [ ! -d "$S_CONFIG_FOLDER" ]; then
                        mkdir -p "$S_CONFIG_FOLDER"
                    fi
                    echo -e "Info: Linking file..."
                    if [ "$model" = "K1" ]; then
                        ln -sf "$USEFUL_MACROS_URL" "$S_CONFIG_FOLDER"/useful-macros.cfg
                    else
                        ln -sf "$USEFUL_MACROS_3V3_URL" "$S_CONFIG_FOLDER"/useful-macros.cfg
                    fi
                    if grep -q "include 3dp-toolkit/useful-macros" "$PRINTER_CFG" ; then
                        echo -e "Info: Useful Macros configurations are already enabled in printer.cfg file..."
                    else
                        echo -e "Info: Adding Useful Macros configurations in printer.cfg file..."
                        sed -i '/\[include printer_params\.cfg\]/a \[include 3dp-toolkit/useful-macros\.cfg\]' "$PRINTER_CFG"
                    fi
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Useful Macros have been installed successfully!"
                fi
                return 0
                ;;
            N|n)
                return 0
                ;;
            *)
                error_msg "Please select a correct choice!"
                ;;
        esac
    done
}

setup_save_zoffset_macros()
{
    local yn installed=0
    if check_file "$SAVE_ZOFFSET_FILE"; then
        installed=1
    fi
    while true; do
        if [ "$installed" = 1 ]; then
            remove_msg "Save Z-Offset Macros" yn || return 1
        else
            install_msg "Save Z-Offset Macros" yn || return 1
        fi
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                if [ "$installed" = 1 ]; then
                    echo -e "Info: Removing file..."
                    rm -f "$S_CONFIG_FOLDER"/save-zoffset.cfg
                    rm -f "$S_CONFIG_FOLDER"/variables.cfg
                    if grep -q "include 3dp-toolkit/save-zoffset" "$PRINTER_CFG" ; then
                        echo -e "Info: Removing Save Z-Offset Macros configurations in printer.cfg file..."
                        sed -i '/include 3dp-toolkit\/save-zoffset\.cfg/d' "$PRINTER_CFG"
                    else
                        echo -e "Info: Save Z-Offset Macros configurations are already removed in printer.cfg file..."
                    fi
                    if [ ! -n "$(ls -A "$S_CONFIG_FOLDER")" ]; then
                        rm -rf "$S_CONFIG_FOLDER"
                    fi
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Save Z-Offset Macros have been removed successfully!"
                else
                    if [ -f "$S_CONFIG_FOLDER"/save-zoffset.cfg ]; then
                        rm -f "$S_CONFIG_FOLDER"/save-zoffset.cfg
                    fi
                    if [ ! -d "$S_CONFIG_FOLDER" ]; then
                        mkdir -p "$S_CONFIG_FOLDER"
                    fi
                    echo -e "Info: Linking file..."
                    ln -sf "$SAVE_ZOFFSET_URL" "$S_CONFIG_FOLDER"/save-zoffset.cfg
                    if grep -q "include 3dp-toolkit/save-zoffset" "$PRINTER_CFG" ; then
                        echo -e "Info: Save Z-Offset Macros configurations are already enabled in printer.cfg file..."
                    else
                        echo -e "Info: Adding Save Z-Offset Macros configurations in printer.cfg file..."
                        sed -i '/\[include printer_params\.cfg\]/a \[include 3dp-toolkit/save-zoffset\.cfg\]' "$PRINTER_CFG"
                    fi
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Save Z-Offset Macros have been installed successfully!"
                fi
                return 0
                ;;
            N|n)
                return 0
                ;;
            *)
                error_msg "Please select a correct choice!"
                ;;
        esac
    done
}


# install / update

# ESSENTIALS
register_action "$(check_folder_action "$MOONRAKER_FOLDER")"'Moonraker & Nginx' "$S_ACTIONS/moonraker_nginx.sh" install 'K1 K1C'
if check_folder "$MOONRAKER_FOLDER"; then
    register_action "$(check_folder_action "$MOONRAKER_FOLDER")"'Moonraker & Nginx' "$S_ACTIONS/moonraker_nginx.sh" remove 'K1 K1C'
fi
#register_action "$(check_folder_action "$MOONRAKER_FOLDER")"'Moonraker & Nginx'
register_action "$(check_folder_action "$FLUIDD_FOLDER")"'Fluidd' "$S_ACTIONS/fluidd.sh" install 'K1 K1C generic'
if check_folder "$FLUIDD_FOLDER"; then
    register_action "$(check_folder_action "$FLUIDD_FOLDER")"'Fluidd' "$S_ACTIONS/fluidd.sh" remove 'K1 K1C generic'
fi

#register_action "$(check_folder_action "$MAINSAIL_FOLDER")"'Mainsail'

# UTILITIES
register_action "$(check_file_action "$ENTWARE_FILE")"'Entware' "$S_ACTIONS/entware.sh" install 'K1 K1C K1_2025'
if check_file "$ENTWARE_FILE"; then
    register_action "$(check_file_action "$ENTWARE_FILE")"'Entware' "$S_ACTIONS/entware.sh" remove 'K1 K1C K1_2025'
fi
register_action "$(check_file_action "$KLIPPER_SHELL_FILE")"'Klipper Gcode Shell Command' setup_gcode_shell_command install 'K1 K1C K1_2025'
if check_file "$KLIPPER_SHELL_FILE"; then
    register_action "$(check_file_action "$KLIPPER_SHELL_FILE")"'Klipper Gcode Shell Command' setup_gcode_shell_command remove 'K1 K1C K1_2025'
fi

# IMPROVEMENTS
register_action "$(check_folder_action "$KAMP_FOLDER")"'Klipper Adaptive Meshing & Purging' "$S_ACTIONS/kamp.sh" install 'K1 K1C'
if check_folder "$KAMP_FOLDER"; then
    register_action "$(check_folder_action "$KAMP_FOLDER")"'Klipper Adaptive Meshing & Purging' "$S_ACTIONS/kamp.sh" remove 'K1 K1C'
fi
register_action "$(check_file_action "$BUZZER_FILE")"'Buzzer Support' setup_buzzer_support install 'K1 K1C'
if check_file "$BUZZER_FILE"; then
    register_action "$(check_file_action "$BUZZER_FILE")"'Buzzer Support' setup_buzzer_support remove 'K1 K1C'
fi
register_action "$(check_folder_action "$NOZZLE_CLEANING_FOLDER")"'Nozzle Cleaning Fan Control' setup_nozzle_cleaning_fan_control install 'K1 K1C'
if check_folder "$NOZZLE_CLEANING_FOLDER"; then
    register_action "$(check_folder_action "$NOZZLE_CLEANING_FOLDER")"'Nozzle Cleaning Fan Control' setup_nozzle_cleaning_fan_control remove 'K1 K1C'
fi
register_action "$(check_file_action "$FAN_CONTROLS_FILE")"'Fans Control Macros' setup_fans_control_macros install 'K1 K1C'
if check_file "$FAN_CONTROLS_FILE"; then
    register_action "$(check_file_action "$FAN_CONTROLS_FILE")"'Fans Control Macros' setup_fans_control_macros remove 'K1 K1C'
fi


register_action "$(check_folder_action "$IMP_SHAPERS_FOLDER")"'Improved Shapers Calibrations' "$S_ACTIONS/improved_shapers.sh" install 'K1 K1C'
if check_folder "$IMP_SHAPERS_FOLDER"; then
    register_action "$(check_folder_action "$IMP_SHAPERS_FOLDER")"'Improved Shapers Calibrations' "$S_ACTIONS/improved_shapers.sh" remove 'K1 K1C'
fi
register_action "$(check_file_action "$USEFUL_MACROS_FILE")"'Useful Macros' setup_useful_macros install 'K1 K1C'
if check_file "$FAN_CONTROLS_FILE"; then
    register_action "$(check_file_action "$USEFUL_MACROS_FILE")"'Useful Macros' setup_useful_macros remove 'K1 K1C'
fi
register_action "$(check_file_action "$SAVE_ZOFFSET_FILE")"'Save Z-Offset Macros' setup_save_zoffset_macros install 'K1 K1C'
if check_file "$FAN_CONTROLS_FILE"; then
    register_action "$(check_file_action "$SAVE_ZOFFSET_FILE")"'Save Z-Offset Macros' setup_save_zoffset_macros remove 'K1 K1C'
fi
#register_action "$(check_file_action "$SCREWS_ADJUST_FILE")"'Screws Tilt Adjust Support'
#register_action "$(check_file_action "$M600_SUPPORT_FILE")"'M600 Support'





# only 2025
#menu_option '12' 'Install' 'Extended Gcode Params'
#menu_option '13' 'Install' 'Start Print Calibration'

# CAMERA
register_action "$(check_file_action "$TIMELAPSE_FILE")"'Moonraker Timelapse' "$S_ACTIONS/moonraker_timelapse.sh" install 'K1 K1C'
if check_file "$TIMELAPSE_FILE"; then
    register_action "$(check_file_action "$TIMELAPSE_FILE")"'Moonraker Timelapse' "$S_ACTIONS/moonraker_timelapse.sh" remove 'K1 K1C'
fi
#register_action "$(check_file_action "$CAMERA_SETTINGS_FILE")"'Camera Settings Control'
#register_action "$(check_file_menu "$USB_CAMERA_FILE")"'USB Camera Support'


# CUSTOMIZATION
register_action "$(check_folder_action "$GUPPY_SCREEN_FOLDER")"'Guppy Screen' "$S_ACTIONS/guppy_screen.sh" install 'K1 K1C'
if check_folder "$GUPPY_SCREEN_FOLDER"; then
    register_action "$(check_folder_action "$GUPPY_SCREEN_FOLDER")"'Guppy Screen' "$S_ACTIONS/guppy_screen.sh" remove 'K1 K1C'
fi




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

