#!/bin/sh

if [ "${TOOLKIT_READY:-}" != 1 ]; then
    printf 'Actions require the toolkit environment. Start main.sh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

ACTION_COMPONENT="Fluidd"

fluidd_install() {
    local yn installed=0 request_restart=1
    if check_folder "$FLUIDD_FOLDER"; then
        installed=1
        request_restart=0
    fi
    while true; do
        if [ "$installed" = 1 ]; then
            update_msg "$ACTION_COMPONENT" yn || return 1
            case "$yn" in
                U|u|update) yn=y ;;
                R|r|remove) fluidd_remove confirmed; return $? ;;
                C|c|cancel) return 0 ;;
                *) error_msg "Please select update, remove, or cancel!"; continue ;;
            esac
        else
            install_msg "$ACTION_COMPONENT" yn || return 1
        fi
        case "${yn}" in
            Y|y)
                echo -e "${white}"

                # download
                echo -e "Info: Downloading Fluidd file..."
                "$CURL" -L "$FLUIDD_URL" -o "$USR_DATA"/fluidd.zip
                echo -e "Info: Creating directory..."
                if [ -d "$FLUIDD_FOLDER" ]; then
                    rm -rf "$FLUIDD_FOLDER"
                fi
                mkdir -p "$FLUIDD_FOLDER"
                mv "$USR_DATA"/fluidd.zip "$FLUIDD_FOLDER"
                echo -e "Info: Extracting files..."
                unzip "$FLUIDD_FOLDER"/fluidd.zip -d "$FLUIDD_FOLDER"
                echo -e "Info: Removing file..."
                rm -f "$FLUIDD_FOLDER"/fluidd.zip
                if grep -q "#\[update_manager fluidd\]" "$MOONRAKER_CFG" ; then
                    echo -e "Info: Enabling Fluidd configurations for Update Manager..."
                    sed -i -e 's/^\s*#[[:space:]]*\[update_manager fluidd\]/[update_manager fluidd]/' -e '/^\[update_manager fluidd\]/,/^\s*$/ s/^\(\s*\)#/\1/' "$MOONRAKER_CFG"
                    request_restart=1
                else
                    echo -e "Info: Fluidd configurations are already enabled for Update Manager..."
                fi

                if [ "$request_restart" = 1 ]; then
                    echo -e "Info: Restarting Nginx service..."
                    restart_nginx
                    echo -e "Info: Restarting Moonraker service..."
                    stop_moonraker
                    start_moonraker
                fi

                if [ "$installed" = 1 ]; then
                    ok_msg "$ACTION_COMPONENT has been updated successfully!"
                    echo -e "   You can now connect to Fluidd Web Interface with ${yellow}http://$(check_ipaddress):4408${white}"
                else
                
                    ok_msg "$ACTION_COMPONENT has been installed successfully!"
                    echo -e "   You can now connect to Fluidd Web Interface with ${yellow}http://$(check_ipaddress):4408${white}"
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

fluidd_remove() {
    local yn
    while true; do
        if [ "${1:-}" = confirmed ]; then
            yn=y
        else
            remove_msg "$ACTION_COMPONENT" yn || return 1
        fi
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                echo -e "Info: Removing files..."
                rm -rf "$FLUIDD_FOLDER"
                if grep -q "\[update_manager fluidd\]" "$MOONRAKER_CFG" ; then
                    echo -e "Info: Disabling $ACTION_COMPONENT configurations for Update Manager..."
                    sed -i '/^\[update_manager fluidd\]/,/^\s*$/ s/^\(\s*\)\([^#]\)/#\1\2/' "$MOONRAKER_CFG"
                    echo -e "Info: Restarting Nginx service..."
                    restart_nginx
                    echo -e "Info: Restarting Moonraker service..."
                    stop_moonraker
                    start_moonraker
                else
                    echo -e "Info: $ACTION_COMPONENT configurations are already disabled for Update Manager..."
                fi
                ok_msg "$ACTION_COMPONENT has been removed successfully!"
                return;;
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
    install|fluidd_install) fluidd_install ;;
    remove|fluidd_remove) fluidd_remove ;;
    *) printf 'Invalid %s action. Select %s under Install / Update or Remove in the toolkit menu.\n' "$ACTION_COMPONENT" "$ACTION_COMPONENT" >&2; return 1 2>/dev/null || exit 1 ;;
esac
