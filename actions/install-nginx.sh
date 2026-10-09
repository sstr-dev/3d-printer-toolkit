#!/bin/sh

if [ "${TOOLKIT_READY:-}" != 1 ]; then
    printf 'Actions require the toolkit environment. Start main.sh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

# TODO: Implement nginx installation and update for the selected printer.
printf 'nginx installation / update is not implemented yet.\n'
