#!/bin/sh

# Run shared startup hooks, then hooks for PRINTER_MODEL, in filename order.
# Uses: S_ACTIONS and initialized paths. Generic skips shared hooks.
# Hooks run in the current shell. Returns: 0 success, 1 invalid model/failure.
run_printer_selection_actions() {
    # Keep the model inside its own action directory.
    case "$PRINTER_MODEL" in
        ''|.|..|*[!a-zA-Z0-9_-]*)
            printf 'Invalid printer model: %s\n' "$PRINTER_MODEL" >&2
            return 1 ;;
    esac

    # actions for all (exclude generic) all-printers
    if [ "$PRINTER_MODEL" != "generic" ]; then
        for printer_selection_script in "$S_ACTIONS/on-select/all-printers"/*.sh; do
            [ -f "$printer_selection_script" ] || continue
            if ! . "$printer_selection_script"; then
                printf 'Printer selection action failed: %s\n' "$printer_selection_script" >&2
                return 1
            fi
        done
    fi

    # actions for selection
    for printer_selection_script in "$S_ACTIONS/on-select/$PRINTER_MODEL"/*.sh; do
        [ -f "$printer_selection_script" ] || continue
        if ! . "$printer_selection_script"; then
            printf 'Printer selection action failed: %s\n' "$printer_selection_script" >&2
            return 1
        fi
    done
    return 0
}
