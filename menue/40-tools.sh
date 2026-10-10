#!/bin/sh

clear_cache() {
    echo
    local yn gc_ok
    while true; do
        read -p "${white} Are you sure you want to ${green}clear cache ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn || yn=n
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                echo -e "Info: Clearing root partition cache..."
                rm -rf /root/.cache
                echo -e "Info: Clearing git cache..."
                gc_ok=1
                git -C "${PROJECT_ROOT}" gc --aggressive --prune=all || { gc_ok=0; error_msg "Git cache could not be cleared, continuing..."; }
                echo -e "Info: Clearing pip cache..."
                # The printer's stock /usr/bin/pip is 19.3.1, older than the `pip
                # cache` subcommand (pip 20.1), and exits 1 with 'unknown command
                # "cache"'; a newer pip exits 1 with "No matching packages" because
                # /root/.cache, where its cache lives, was removed just above. Under
                # helper.sh's global `set -e` either exit killed the whole helper.
                pip cache purge >/dev/null 2>&1 || true
                if [ "${gc_ok}" = 1 ]; then
                    ok_msg "Cache has been cleared!"
                else
                    ok_msg "Cache has been cleared, except the git cache!"
                fi
                return;;
            N|n)
                error_msg "Clearing cache canceled!"
                return;;
            *)
                error_msg "Please select a correct choice!";;
        esac
    done
}

clear_logs() {
    echo
    local yn
    while true; do
        read -p "${white} Are you sure you want to clear ${green}logs files ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                echo -e "Info: Clearing logs files..."
                rm -f "$USR_DATA"/creality/userdata/log/*.log
                rm -f "$USR_DATA"/creality/userdata/log/*.gz
                rm -f "$USR_DATA"/creality/userdata/fault_code/*
                rm -f "$PRINTER_DATA_FOLDER"/logs/*
                if [ -d "$GUPPYFLO_FOLDER" ]; then
                    rm -f "$GUPPYFLO_FOLDER"/guppyflo.log
                fi
                ok_msg "Logs files have been cleared!"
                return;;
            N|n)
                error_msg "Clearing logs files canceled!"
                return;;
            *)
                error_msg "Please select a correct choice!";;
        esac
    done
}

restore_previous_firmware() {
    local yn
    while true; do
        read -p "${white} Do you want to restore a previous firmware ? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
        case "${yn}" in
            Y|y)
                if ls /tmp/udisk/sda1/*.img 1> /dev/null 2>&1; then
                    echo -e "${white}"
                    echo "Info: Restoring firmware..."
                    rm -rf /overlay/upper/*
                    /etc/ota_bin/local_ota_update.sh /tmp/udisk/sda1/*.img
                    ok_msg "Firmware has been restored! Please reboot your printer."
                    exit 0
                else
                    error_msg "No .img file found on the USB drive. Restoration canceled!"
                fi
                return;;
            N|n)
                error_msg "Restoration canceled!"
                return;;
            *)
                error_msg "Please select a correct choice!";;
        esac
    done
}

reset_factory_settings() {
    local yn
    while true; do
        read -p "${white} Are you sure you want to ${green}reset factory settings ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                "$INITD_FOLDER"/S58factoryreset reset
                ;;
            N|n)
                error_msg "Reset canceled!"
                return;;
            *)
                error_msg "Please select a correct choice!";;
        esac
    done
}



# Basename of the active Klipper init script (S55… or CS55… on newer K1C firmware), or empty.
klipper_init_script_basename() {
    if [ -f "$INITD_FOLDER/S55klipper_service" ]; then
        echo S55klipper_service
    elif [ -f "$INITD_FOLDER/CS55klipper_service" ]; then
        echo CS55klipper_service
    fi
}
klipper_disabled_backup_basename() {
    if [ -f "$INITD_FOLDER/disabled.S55klipper_service" ]; then
        echo disabled.S55klipper_service
    elif [ -f "$INITD_FOLDER/disabled.CS55klipper_service" ]; then
        echo disabled.CS55klipper_service
    fi
}
prevent_allow_updating_klipper_files()
{
    if [ -f "$INITD_FOLDER"/disabled.S55klipper_service ] || [ -f "$INITD_FOLDER"/disabled.CS55klipper_service ]; then
        local yn
        while true; do
            read -p "${white} Do you want to allow updating ${green}Klipper configuration files ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
            case "${yn}" in
                Y|y)
                    echo -e "${white}"
                    disabled_backup="$(klipper_disabled_backup_basename)"
                    if [ -z "$disabled_backup" ]; then
                        error_msg "No disabled Klipper init backup found in ${INITD_FOLDER}."
                        return
                    fi
                    klipper_init="${disabled_backup#disabled.}"
                    echo -e "Info: Restoring file..."
                    rm -f "$INITD_FOLDER/$klipper_init"
                    mv "$INITD_FOLDER/$disabled_backup" "$INITD_FOLDER/$klipper_init"
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Klipper configuration files will be updated when Klipper restarts!"
                    return;;
                N|n)
                    error_msg "Authorization canceled!"
                    return;;
                *)
                    error_msg "Please select a correct choice!";;
            esac
        done
    else
        local yn
        while true; do
            read -p "${white} Do you want to prevent updating ${green}Klipper configuration files ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
            case "${yn}" in
                Y|y)
                    echo -e "${white}"
                    klipper_init="$(klipper_init_script_basename)"
                    if [ -z "$klipper_init" ]; then
                        error_msg "Klipper init script not found in ${INITD_FOLDER} (expected S55klipper_service or CS55klipper_service)."
                        return
                    fi
                    echo -e "Info: Backup file..."
                    mv "$INITD_FOLDER/$klipper_init" "$INITD_FOLDER/disabled.$klipper_init"
                    echo -e "Info: Copying file..."
                    cp "$KLIPPER_SERVICE_URL" "$INITD_FOLDER/$klipper_init"
                    echo -e "Info: Applying permissions..."
                    chmod 755 "$INITD_FOLDER/$klipper_init"
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Klipper configuration files will no longer be updated when Klipper restarts!"
                    return;;
                N|n)
                    error_msg "Preventing canceled!"
                    return;;
                *)
                    error_msg "Please select a correct choice!";;
            esac
        done
    fi
}



check_chassi_light_menu_action() {
    if check_printer_component "output_pin LED"; then
        echo -e '[x] '
    else
        echo -e "[ ] "
    fi
}

change_chassis_light_control()
{
    if ! check_printer_component "output_pin LED"; then
        error_msg "Chassis light control is already present in printer.cfg!"
        return
    fi
    local yn
    while true; do
        read -p "${white} Do you want to add ${green}chassis light control ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                echo -e "Info: Adding chassis light control to printer.cfg..."
                awk '
                    BEGIN { added = 0 }
                    /^\#\*\# <---------------------- SAVE_CONFIG ---------------------->/ && !added {
                        print ""
                        print "[output_pin LED]"
                        print "pin: PA8"
                        print "pwm: True"
                        print "cycle_time: 0.001"
                        print "value: 1"
                        print "shutdown_value: 0"
                        added = 1
                    }
                    { print }
                    END {
                        if (!added) {
                            print ""
                            print "[output_pin LED]"
                            print "pin: PA8"
                            print "pwm: True"
                            print "cycle_time: 0.001"
                            print "value: 1"
                            print "shutdown_value: 0"
                        }
                    }
                ' "$PRINTER_CFG" > "$PRINTER_CFG.tmp" && mv "$PRINTER_CFG.tmp" "$PRINTER_CFG"
                echo -e "Info: Restarting Klipper service..."
                restart_klipper
                ok_msg "Chassis light control has been added successfully!"
                return;;
            N|n)
                return;;
            *)
                error_msg "Please select a correct choice!"
                ;;
        esac
    done
}

printing_gcode_from_folder()
{
    local yn
    while true; do
        read -p "${white} Do you want to apply fix for ${green}printing Gcode files from folder ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                echo -e "Info: Deleting files..."
                if [ -f "$KLIPPER_KLIPPY_FOLDER"/gcode.py ]; then
                    rm -f "$KLIPPER_KLIPPY_FOLDER"/gcode.py
                    rm -f "$KLIPPER_KLIPPY_FOLDER"/gcode.pyc
                fi
                echo -e "Info: Linking files..."
                if [ "$PRINTER_MODEL" = "K1" ] || [ "$PRINTER_MODEL" = "K1C" ]; then
                    ln -sf "$KLIPPER_GCODE_URL" "$KLIPPER_KLIPPY_FOLDER"/gcode.py
                fi
                if [ "$PRINTER_MODEL" = "3V3" ]; then
                    ln -sf "$KLIPPER_GCODE_3V3_URL" "$KLIPPER_KLIPPY_FOLDER"/gcode.py
                fi
                echo -e "Info: Restarting Klipper service..."
                restart_klipper
                ok_msg "Fix has been applied successfully!"
                return;;
            N|n)
                error_msg "Installation canceled!"
                return;;
            *)
                error_msg "Please select a correct choice!";;
        esac
    done
}

check_camera_settings_menu_action()
{
    if check_moonraker_component "webcam Camera"; then
        echo -e '[x] '
    else
        echo -e "[ ] "
    fi
}


configure_usb_camera_k1_2025()
{
    local usb_dev

    if [ ! -f "$MOONRAKER_CFG" ]; then
        return
    fi

    usb_dev=$(v4l2-ctl --list-devices | grep -A1 usb | sed 's/^[[:space:]]*//g' | grep '^/dev' | grep -v '^/dev/video0$' | head -n 1)
    if [ -n "$usb_dev" ]; then
        echo -e "Info: Configuring USB camera in moonraker.conf..."
        sed -i '/^\[webcam usb\]/,/^$/d' "$MOONRAKER_CFG"
        cat >> "$MOONRAKER_CFG" <<EOF

[webcam usb]
enabled: True
location: printer
service: mjpegstreamer
target_fps: 15
target_fps_idle: 5
stream_url: /webcam3/?action=stream
snapshot_url: /webcam3/?action=snapshot
flip_horizontal: False
flip_vertical: False
rotation: 0
aspect_ratio: 16:9
EOF
    fi
}

configure_builtin_camera_k1_2025()
{
    if [ ! -f "$MOONRAKER_CFG" ]; then
        return
    fi

    echo -e "Info: Configuring built-in camera in moonraker.conf..."
    sed -i '/^\[webcam chassis\]/,/^$/d' "$MOONRAKER_CFG"
    cat >> "$MOONRAKER_CFG" <<EOF

[webcam chassis]
enabled: True
location: printer
service: mjpegstreamer
target_fps: 15
target_fps_idle: 5
stream_url: /webcam/?action=stream
snapshot_url: /webcam/?action=snapshot
flip_horizontal: False
flip_vertical: False
rotation: 0
aspect_ratio: 16:9
EOF
}

change_camera_settings()
{
    if check_moonraker_component_action "webcam Camera"; then
        local yn
        while true; do
            read -p "${white} Do you want to enable ${green}camera settings in Moonraker ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
            case "${yn}" in
                Y|y)
                    echo -e "${white}"
                    if [ "$PRINTER_MODEL" = "K1_2025" ]; then
                        if grep -q "^\[webcam chassis\]\|^\[webcam usb\]" "$MOONRAKER_CFG"; then
                            echo -e "Info: Disabling camera settings in moonraker.conf file..."
                            sed -i '/^\[webcam chassis\]/,/^$/d' "$MOONRAKER_CFG"
                            sed -i '/^\[webcam usb\]/,/^$/d' "$MOONRAKER_CFG"
                        else
                            echo -e "Info: Camera settings are already disabled in moonraker.conf file..."
                        fi
                    elif grep -q "\[webcam Camera\]" "$MOONRAKER_CFG" ; then
                        echo -e "Info: Disabling camera settings in moonraker.conf file..."
                        sed -i '/^\[webcam Camera\]/,/^\s*$/ s/^\(\s*\)\([^#]\)/#\1\2/' "$MOONRAKER_CFG"
                    else
                        echo -e "Info: Camera settings are already disabled in moonraker.conf file..."
                    fi
                    echo -e "Info: Restarting Moonraker service..."
                    stop_moonraker
                    start_moonraker
                    ok_msg "Camera settings have been disabled in Moonraker successfully!"
                    return;;
                N|n)
                    error_msg "Deactivation canceled!"
                    return;;
                *)
                    error_msg "Please select a correct choice!";;
            esac
        done
    else
        local yn
        while true; do
            read -p "${white} Do you want to prevent updating ${green}Klipper configuration files ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn
            case "${yn}" in
                Y|y)
                    echo -e "${white}"
                    if [ "$PRINTER_MODEL" = "K1_2025" ]; then
                        if [ -f "$BUILTIN_CAMERA_FILE" ] || [ -f "$BUILTIN_CAMERA_LEGACY_FILE" ]; then
                            configure_builtin_camera_k1_2025
                        fi
                        if [ -f "$USB_CAMERA_FILE" ] || [ -f "$USB_CAMERA_LEGACY_FILE" ]; then
                            configure_usb_camera_k1_2025
                        fi
                    elif grep -q "#\[webcam Camera\]" "$MOONRAKER_CFG" ; then
                        echo -e "Info: Enabling camera settings in moonraker.conf file..."
                        sed -i -e 's/^\s*#[[:space:]]*\[webcam Camera\]/[webcam Camera]/' -e '/^\[webcam Camera\]/,/^\s*$/ s/^\(\s*\)#/\1/' "$MOONRAKER_CFG"
                    else
                        echo -e "Info: Camera settings are already enabled in moonraker.conf file..."        
                    fi
                    local ip_address
                    ip_address="$(check_ipaddress)"
                    if grep -q "stream_url: http://xxx.xxx.xxx.xxx:8080/?action=stream" "$MOONRAKER_CFG"; then
                        echo -e "Info: Replacing stream_url IP address..."
                        sed -i "s|http://xxx.xxx.xxx.xxx:|http://$ip_address:|g" "$MOONRAKER_CFG"
                    fi
                    if grep -q "snapshot_url: http://xxx.xxx.xxx.xxx:8080/?action=snapshot" "$MOONRAKER_CFG"; then
                        echo -e "Info: Replacing snapshot_url IP address..."
                        sed -i "s|http://xxx.xxx.xxx.xxx:|http://$ip_address:|g" "$MOONRAKER_CFG"
                    fi
                    echo -e "Info: Restarting Moonraker service..."
                    stop_moonraker
                    start_moonraker
                    ok_msg "Camera settings have been enabled in Moonraker successfully!"
                    return;;
                N|n)
                    error_msg "Activation canceled!"
                    return;;
                *)
                    error_msg "Please select a correct choice!";;
            esac
        done
    fi
}


register_action "$(check_klipper_update_allow_action)"'Allow Updating Klipper configuration files' prevent_allow_updating_klipper_files tools 'K1C K1_2025'

register_action 'Fix printing Gcode files from folder' printing_gcode_from_folder tools 'K1 K1C'

register_action "$(check_camera_settings_menu_action)"'Camera settings in Moonraker' change_camera_settings tools 'K1 K1C'


if check_folder "$MOONRAKER_FOLDER"; then
    register_action 'Restart -> Moonraker' restart_moonraker_action tools 'K1C K1_2025'
fi
if check_folder "$NGINX_FOLDER"; then
    register_action 'Restart -> Nginx' restart_nginx_action tools 'K1C K1_2025'
fi
if check_file "$INITD_FOLDER"/CS55klipper_service || check_file "$INITD_FOLDER"/S55klipper_service; then
    register_action 'Restart -> Klipper' restart_klipper_action tools 'K1C K1_2025'
fi

register_action "$(check_chassi_light_menu_action)"'Chassis light control' change_chassis_light_control tools 'K1C K1_2025'

register_action 'Clear - cache' clear_cache tools 'K1C K1_2025'
register_action 'Clear - logs files' clear_logs tools 'K1C K1_2025'
register_action 'Restore a previous firmware' restore_previous_firmware tools 'K1C'
register_action 'Reset factory settings' reset_factory_settings tools 'K1C'

# register_action 'Backup configuration (example)' "$S_ACTIONS/backup-configuration.sh" tools 'K1C'
