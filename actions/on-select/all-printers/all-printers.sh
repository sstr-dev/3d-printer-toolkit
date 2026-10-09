#!/bin/sh

if [ "${TOOLKIT_READY:-}" != 1 ]; then
    printf 'Actions require the toolkit environment. Start main.sh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

if [ ! -L "$BIN_FOLDER"/3dp ]; then
  ln -sf "$PROJECT_ROOT"/main.sh "$BIN_FOLDER"/3dp > /dev/null 2>&1
fi

rm -rf /root/.cache

set_permissions

if [ -z "$PRINTER_MODEL" ] && [ "$PRINTER_MODEL" != "K1_2025" ] && [ ! -f $INITD_FOLDER/S58factoryreset ]; then
  cp "$S_FILES/services/S58factoryreset" $INITD_FOLDER/S58factoryreset
  chmod 755 $INITD_FOLDER/S58factoryreset
fi
