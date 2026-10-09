#!/bin/sh

if [ "${TOOLKIT_READY:-}" != 1 ]; then
    printf 'Actions require the toolkit environment. Start main.sh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

ACTION_COMPONENT="Entware"

entware_install() {
    local yn
    while true; do
        install_msg "$ACTION_COMPONENT" yn || return 1
        case "${yn}" in
            Y|y)
                if check_file "$ENTWARE_FILE"; then
                    while true; do
                        update_msg "$ACTION_COMPONENT" yn || return 1
                        case "${yn}" in
                            Y|y)
                                # TODO: Implement Entware update.
                                warn_msg "$ACTION_COMPONENT update is not implemented yet."
                                return 1
                                ;;
                            N|n)
                                return 0
                                ;;
                            *)
                                error_msg "Please select a correct choice!"
                                ;;
                        esac
                    done
                else
                    warn_msg "$ACTION_COMPONENT installation / update is not implemented yet."

                    return 1
                fi
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

entware_remove() {
    local yn
    while true; do
        remove_msg "$ACTION_COMPONENT" yn || return 1
        case "${yn}" in
            Y|y)
                # TODO: Implement Entware removal for the selected printer.
                warn_msg "$ACTION_COMPONENT removal is not implemented yet."
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
    install|entware_install) entware_install ;;
    remove|entware_remove) entware_remove ;;
    *) printf 'Invalid %s action. Select %s under Install / Update or Remove in the toolkit menu.\n' "$ACTION_COMPONENT" "$ACTION_COMPONENT" >&2; return 1 2>/dev/null || exit 1 ;;
esac
