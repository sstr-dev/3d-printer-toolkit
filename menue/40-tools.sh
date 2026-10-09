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

register_action "$(check_klipper_update_allow_action)"'Allow Updating Klipper configuration files' prevent_allow_updating_klipper_files tools 'K1C K1_2025'

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
