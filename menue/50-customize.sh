#!/bin/sh

#register_action 'Change hostname (example)' "$PROJECT_ROOT/actions/change-hostname.sh" customize 'K1C generic'

block_creality_cloud()
{
    if check_file "$CLOUD_BLOCK_SERVICE_FILE"; then
        while true; do
            remove_msg "Block Creality Cloud Telemetry" yn || return 1
            case "${yn}" in
                Y|y)
                    echo -e "${white}"
                    echo -e "Info: Restoring hosts file and removing rules..."
                    set +e
                    if [ -f "$CLOUD_BLOCK_SERVICE_FILE" ]; then
                        "$CLOUD_BLOCK_SERVICE_FILE" stop
                    fi
                    set -e
                    echo -e "Info: Removing file..."
                    rm -f "$CLOUD_BLOCK_SERVICE_FILE"
                    ok_msg "Block Creality Cloud Telemetry has been removed successfully!"
                    return;;
                N|n)
                    return 0
                    ;;
                *)
                    error_msg "Please select a correct choice!"
                    ;;
            esac
        done
    else
        echo -e "${white}"
        echo -e "Info: Copying service file..."
        cp "$CLOUD_BLOCK_SERVICE_URL" "$CLOUD_BLOCK_SERVICE_FILE"
        chmod 755 "$CLOUD_BLOCK_SERVICE_FILE"
        echo -e "Info: Applying blocklist..."
        local start_rc
        set +e
        "$CLOUD_BLOCK_SERVICE_FILE" start
        start_rc=$?
        set -e
        if [ "$start_rc" -ne 0 ]; then
            error_msg "Block Creality Cloud Telemetry was installed but did not apply cleanly!"
            echo -e " ${darkred}Run '$CLOUD_BLOCK_SERVICE_FILE status' to see what is missing.${white}"
            echo
            return
        fi
        ok_msg "Block Creality Cloud Telemetry has been installed successfully!"
        if ! command -v iptables > /dev/null 2>&1; then
            echo -e " ${darkred}Note: this printer has no iptables, so the MQTT port rules were skipped.${white}"
            echo -e " ${darkred}The hosts blocklist is still active.${white}"
            echo
        fi
        echo -e " ${white}Connections already open are not torn down, reboot to apply it fully.${white}"
        echo
        return
    fi
}

creality_web_interface()
{
    if [ -f "$CREALITY_WEB_FILE" ]; then
        # is installed, remove?
        while true; do
            remove_msg "Creality Web Interface" yn || return 1
            case "${yn}" in
                Y|y)

                    echo -e "${white}"
                    echo -e "Info: Disabling files..."
                    if [ -f /usr/bin/web-server ]; then
                        mv /usr/bin/web-server /usr/bin/web-server.disabled
                    fi
                    if [ -f /usr/bin/Monitor ]; then
                        mv /usr/bin/Monitor /usr/bin/Monitor.disabled
                    fi
                    echo -e "Info: Stopping services..."
                    set +e
                    killall -q Monitor
                    killall -q web-server
                    set -e
                    echo -e "Info: Restarting Nginx service..."
                    restart_nginx
                    ok_msg "Creality Web Interface has been removed successfully!"
                    return;;
                N|n)
                    return 0
                    ;;
                *)
                    error_msg "Please select a correct choice!"
                    ;;
            esac
        done
    else
        # install, check Guppy
        if [ ! -f "$INITD_FOLDER"/S99start_app ]; then
            error_msg "Guppy Screen need to be removed first to restore Creality Web Interface!"
        else
            # restore_creality_web_interface
            # nginx installed?
            # change port back to xxxx

            echo -e "Info: Restoring files..."
            if [ -f /usr/bin/web-server.disabled ] && [ -f "$INITD_FOLDER"/S99start_app ]; then
                mv /usr/bin/web-server.disabled /usr/bin/web-server
            fi
            if [ -f /usr/bin/Monitor.disabled ] && [ ! -d "$GUPPY_SCREEN_FOLDER" ]; then
                mv /usr/bin/Monitor.disabled /usr/bin/Monitor
            fi
            echo -e "Info: Restarting services..."
            restart_nginx
            set +e
            killall -q Monitor
            killall -q web-server
            set -e
            if [ -f /usr/bin/web-server ] && [ -f "$INITD_FOLDER"/S99start_app ]; then
                /usr/bin/web-server > /dev/null 2>&1 &
            fi
            if [ -f /usr/bin/Monitor ] && [ ! -d "$GUPPY_SCREEN_FOLDER" ]; then
                /usr/bin/Monitor > /dev/null 2>&1 &
            fi
            ok_msg "Creality Web Interface has been restored successfully!"
        fi
    fi
}

extra_macros()
{
    # Extra macros #
    # EXTRA_MACROS_FOLDER="${S_CONFIG_FOLDER}/macros"
    # EXTRA_MACROS_URL="${S_FILES}/macros/extra"

    # at the end: copy dist loader (includes only calibration)
    # calibration and misc, copy loader,   _dist: symbolic link    is installed, update or renmove?
    # filaman, spoolman
    local yn installed=0 request_restart=1
    if check_folder "$EXTRA_MACROS_FOLDER"; then
        installed=1
        request_restart=0
    fi
    while true; do
        if [ "$installed" = 1 ]; then
            update_msg "Extra macros" yn || return 1
            case "$yn" in
                U|u|update) yn=y ;;
                R|r|remove) yn=r ;;
                C|c|cancel) return 0 ;;
                *) error_msg "Please select update, remove, or cancel!"; continue ;;
            esac
        else
            install_msg "Extra macros" yn || return 1
        fi
        case "${yn}" in
            R|r)
                echo -e "${white}"
                echo -e "Info: Removing files..." 
                rm -rf "$EXTRA_MACROS_FOLDER"
                rm -f "$S_CONFIG_FOLDER"/macros_loader.cfg                
                if grep -q "include 3dp-toolkit/macros_loader" "$PRINTER_CFG" ; then
                    echo -e "Info: Removing Extra macros configurations in printer.cfg file..."
                    sed -i '/include 3dp-toolkit\/macros_loader\.cfg/d' "$PRINTER_CFG"
                else
                    echo -e "Info: Extra macros configurations are already removed in printer.cfg file..."
                fi
                echo -e "Info: Restarting Klipper service..."
                restart_klipper
                ok_msg "Extra macros has been removed successfully!"
                return
                ;;
            Y|y)
                echo -e "${white}"

                echo -e "Info: Creating directories..."
                if [ ! -d "$S_CONFIG_FOLDER" ]; then
                    mkdir -p "$S_CONFIG_FOLDER"
                fi
                if [ ! -d "$EXTRA_MACROS_FOLDER" ]; then
                    mkdir -p "$EXTRA_MACROS_FOLDER"
                fi

                echo -e "Info: Linking files and housekeeping..."
                local source_folder target_folder source_file target_file
                for source_folder in "$EXTRA_MACROS_URL"/*; do
                    [ -d "$source_folder" ] || continue
                    target_folder="$EXTRA_MACROS_FOLDER/${source_folder##*/}"
                    mkdir -p "$target_folder"
                    for source_file in "$source_folder"/*.cfg; do
                        [ -f "$source_file" ] || continue
                        target_file="$target_folder/${source_file##*/}"
                        [ -e "$target_file" ] || ln -sf "$source_file" "$target_file"
                    done
                    find "$target_folder" -type l ! -exec test -e {} \; -exec rm -f {} \;
                done

                # Copy the loader.cfg template to the printer as macros_loader.cfg.
                if check_file "$S_CONFIG_FOLDER"/macros_loader.cfg; then
                    local yn_ov
                    printf 'macros_loader already exists, if you made manual changes select N. Overwrite? (y/N): '
                    IFS= read -r yn_ov || return 1
                    case "$yn_ov" in
                        Y|y) 
                            request_restart=1
                            cp -r "$EXTRA_MACROS_URL"/loader.cfg "$S_CONFIG_FOLDER"/macros_loader.cfg ;;
                    esac
                else
                    request_restart=1
                    cp "$EXTRA_MACROS_URL"/loader.cfg "$S_CONFIG_FOLDER"/macros_loader.cfg
                fi

                # Check printer.cfg
                if grep -q "include 3dp-toolkit/macros_loader" "$PRINTER_CFG" ; then
                    echo -e "Info: Extra macros configurations are already enabled in printer.cfg file..."
                else
                    echo -e "Info: Adding Extra macros configurations in printer.cfg file..."
                    sed -i '/\[include printer_params\.cfg\]/a [include 3dp-toolkit/macros_loader.cfg]' "$PRINTER_CFG"
                    request_restart=1
                fi

                if [ "$request_restart" = 1 ]; then
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                fi

                if [ "$installed" = 1 ]; then
                    ok_msg "Extra macros has been updated successfully!"
                else
                
                    ok_msg "Extra macros has been installed successfully!"
                fi
                return 0
                ;;
            N|n)
                error_msg "Installation canceled!"
                return
                ;;
            *)
                error_msg "Please select a correct choice!"
                ;;
        esac
    done
}


register_action "$(check_file_action "$CREALITY_WEB_FILE")"'Creality Web Interface' creality_web_interface customize 'K1 K1C'
register_action "$(check_file_action "$CLOUD_BLOCK_SERVICE_FILE")"'Block Creality Cloud Telemetry' block_creality_cloud customize 'K1 K1C'

# MACROS
register_action "$(check_folder_action "$EXTRA_MACROS_FOLDER")"'Extra macros' extra_macros customize 'K1 K1C'



#subtitle '•CUSTOMIZATION:'
#info_line "$(check_file_action "$BOOT_DISPLAY_FILE")" 'Custom Boot Display'
#info_line "$(check_file_action "$FLUIDD_LOGO_FILE")" 'Creality Dynamic Logos for Fluidd'
