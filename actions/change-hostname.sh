#!/bin/sh

if [ "${TOOLKIT_READY:-}" != 1 ]; then
    printf 'Actions require the toolkit environment. Start main.sh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

# TODO: Implement hostname customization for the selected printer.
printf 'Hostname customization is not implemented yet.\n'
