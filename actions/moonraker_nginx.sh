#!/bin/sh

if [ "${TOOLKIT_READY:-}" != 1 ]; then
    printf 'Actions require the toolkit environment. Start main.sh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

ACTION_COMPONENT="Moonraker and Nginx"


install_helper_shims()
{
    # Install the supervisorctl/systemctl/sudo shims as real files (not symlinks):
    # a symlink rooted at the helper-script folder dangles if that folder is later
    # renamed, leaving a broken entry on PATH that Moonraker hits as FileNotFound.
    echo -e "Info: Installing Supervisor Lite..."
    cp -f "$SUPERVISOR_URL" "$SUPERVISOR_FILE"
    chmod 755 "$SUPERVISOR_FILE"
    # K1C 2025: BIN_FOLDER (/usr/apps/usr/bin) is only on Moonraker's PATH at boot.
    # The launcher always prepends /opt/bin (Entware), so a copy there is found on
    # manual restarts too. Guarded on Entware being mounted; no-op on other models.
    if [ "$PRINTER_MODEL" = "K1_2025" ] && [ -d /opt/bin ]; then
        cp -f "$SUPERVISOR_URL" "$SUPERVISOR_OPT_FILE"
        chmod 755 "$SUPERVISOR_OPT_FILE"
    fi
    echo -e "Info: Installing Host Controls Support..."
    cp -f "$SUDO_URL" "$SUDO_FILE"
    chmod 755 "$SUDO_FILE"
    cp -f "$SYSTEMCTL_URL" "$SYSTEMCTL_FILE"
    chmod 755 "$SYSTEMCTL_FILE"
}
remove_helper_shims()
{
    rm -f "$SUPERVISOR_FILE" "$SUDO_FILE" "$SYSTEMCTL_FILE"
    [ "$PRINTER_MODEL" = "K1_2025" ] && rm -f "$SUPERVISOR_OPT_FILE"
}

moonraker_nginx_install()
{
    local yn
    if check_folder "$MOONRAKER_FOLDER"; then
        error_msg "$ACTION_COMPONENT is already installed!"
    else
        while true; do
            install_msg "$ACTION_COMPONENT" yn || return 1
            case "${yn}" in
                Y|y)
                    echo -e "Info: Extracting Moonraker files..."
                    tar -xvf "$MOONRAKER_URL1" -C "$USR_DATA"
                    echo -e "Info: Extracting Nginx files..."
                    tar -xvf "$NGINX_URL" -C "$USR_DATA"
                    echo -e "Info: Copying services files..."
                    if [ ! -f "$INITD_FOLDER"/S50nginx ]; then
                        cp "$NGINX_SERVICE_URL" "$INITD_FOLDER"/S50nginx
                        chmod +x "$INITD_FOLDER"/S50nginx
                    fi
                    if [ ! -f "$INITD_FOLDER"/S56moonraker_service ]; then
                        cp "$MOONRAKER_SERVICE_URL" "$INITD_FOLDER"/S56moonraker_service
                        chmod +x "$INITD_FOLDER"/S56moonraker_service
                    fi
                    echo -e "Info: Copying Moonraker configuration file..."
                    if [ -f "$KLIPPER_CONFIG_FOLDER"/moonraker.conf ]; then
                        rm -f "$KLIPPER_CONFIG_FOLDER"/moonraker.conf
                    fi
                        cp "$MOONRAKER_URL2" "$KLIPPER_CONFIG_FOLDER"/moonraker.conf
                    if [ -f "$PRINTER_DATA_FOLDER"/moonraker.asvc ]; then
                        rm -f "$PRINTER_DATA_FOLDER"/moonraker.asvc
                    fi
                    cp "$MOONRAKER_URL3" "$PRINTER_DATA_FOLDER"/moonraker.asvc
                    echo -e "Info: Applying changes from official repo..."
                    cd "$MOONRAKER_FOLDER"/moonraker
                    chown -R root:root .
                    git stash; git checkout master; git pull
                    install_helper_shims
                    echo -e "Info: Starting Nginx service..."
                    start_nginx
                    echo -e "Info: Starting Moonraker service..."
                    start_moonraker
                    ok_msg "Moonraker and Nginx have been installed successfully!"
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
    fi
}

moonraker_nginx_remove() {
    local yn
    while true; do
        remove_msg "$ACTION_COMPONENT" yn || return 1
        case "${yn}" in
            Y|y)
                echo -e "Info: Stopping Moonraker and Nginx services..."
                stop_moonraker
                stop_nginx
                echo -e "Info: Removing files..."
                rm -f "$INITD_FOLDER"/S50nginx
                rm -f "$INITD_FOLDER"/S56moonraker_service
                rm -f "$KLIPPER_CONFIG_FOLDER"/moonraker.conf
                rm -f "$KLIPPER_CONFIG_FOLDER"/.moonraker.conf.bkp
                rm -f "$PRINTER_DATA_FOLDER"/.moonraker.uuid
                rm -f "$PRINTER_DATA_FOLDER"/moonraker.asvc
                rm -rf "$PRINTER_DATA_FOLDER"/comms
                rm -rf "$NGINX_FOLDER"
                rm -rf "$MOONRAKER_FOLDER"
                remove_helper_shims
                ok_msg "Moonraker and Nginx have been removed successfully!"
                return 0
                ;;
            N|n)
                error_msg "Removal canceled!"
                return
                ;;
            *)
                error_msg "Please select a correct choice!"
                ;;
        esac
    done
}

case "${1:-}" in
    install|moonraker_nginx_install) moonraker_nginx_install ;;
    remove|moonraker_nginx_remove) moonraker_nginx_remove ;;
    *) printf 'Invalid %s action. Select %s under Install / Update or Remove in the toolkit menu.\n' "$ACTION_COMPONENT" "$ACTION_COMPONENT" >&2; return 1 2>/dev/null || exit 1 ;;
esac
