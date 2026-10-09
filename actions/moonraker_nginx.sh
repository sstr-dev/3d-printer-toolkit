#!/bin/sh

if [ "${TOOLKIT_READY:-}" != 1 ]; then
    printf 'Actions require the toolkit environment. Start main.sh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

ACTION_COMPONENT="Moonraker and Nginx"

moonraker_nginx_install() {
    local yn
    while true; do
        install_msg "$ACTION_COMPONENT" yn || return 1
        case "${yn}" in
            Y|y)
                # TODO: Implement Moonraker installation / update for the selected printer.
                
                # update or install
                ## verify nginx setup

                ## verify moonraker setup

                warn_msg 'Moonraker installation / update is not implemented yet.'
                return 1
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

moonraker_nginx_remove() {
    local yn
    while true; do
        remove_msg "$ACTION_COMPONENT" yn || return 1
        case "${yn}" in
            Y|y)
                # TODO: Implement Moonraker removal for the selected printer.
                warn_msg 'Moonraker removal is not implemented yet.'
                return 1
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
