#!/bin/sh

if [ "${TOOLKIT_READY:-}" != 1 ]; then
    printf 'Actions require the toolkit environment. Start main.sh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

moonraker_install() {
    # TODO: Implement Moonraker installation and update for the selected printer.
    # Split Moonraker and nginx installation into separate parts.
    # Prepare and pack the Moonraker application environment separately.
    printf 'Moonraker installation / update is not implemented yet.\n'
}

moonraker_remove() {
    # TODO: Implement Moonraker removal for the selected printer.
    printf 'Moonraker removal is not implemented yet.\n'
}

case "${1:-}" in
    install|moonraker_install) moonraker_install ;;
    remove|moonraker_remove) moonraker_remove ;;
    *) printf 'Invalid Moonraker action. Select Moonraker under Install / Update or Remove in the toolkit menu.\n' >&2; return 1 2>/dev/null || exit 1 ;;
esac
