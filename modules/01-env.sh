#!/bin/sh

# Read system details and initialize the selected printer model.
# Sets: OS_NAME, ARCHITECTURE, PRINTER_MODEL.
# Automatic detection is incomplete; unknown models need manual selection.
detect_model() {
    OS_NAME=$(uname -s)
    ARCHITECTURE=$(uname -m)
    PRINTER_MODEL=${PRINTER_MODEL:-unknown}
    if [ "$PRINTER_MODEL" = unknown ]; then
        if (command -v get_sn_mac.sh > /dev/null); then
            get_model=$( get_sn_mac.sh model 2>&1 || echo "")
            if [ -z "$get_model" ] && get_sn_mac.sh model_str 2>&1 | grep -iq 'K1'; then
                #K1 2025, K1Max 2025, ...
                PRINTER_MODEL="K1_2025"
            elif echo "$get_model" | grep -iq "K1C"; then
                PRINTER_MODEL="K1C"
            else
                echo "Unsupported model!" > /dev/stderr
            fi
        fi
        for model_file in /etc/model /etc/board.json /usr/data/printer_data/config/printer.cfg; do
            [ -r "$model_file" ] || continue
            #if grep -qi 'K1C' "$model_file"; then
            #    PRINTER_MODEL=K1C
            #    break
            #fi
        done
    fi
}

# Ask for a printer when PRINTER_MODEL is unknown.
# Sets: PRINTER_MODEL. Returns: 0 selected/already set, 1 cancelled.
select_printer() {
    [ "$PRINTER_MODEL" = unknown ] || return 0
    while true; do
        printer_selection=$(menu_select 'Select printer' '1|Creality K1C (pre-2025)
2|Generic / development
3|Creality K1 (pre-2025)
4|Creality K1 series (2025)
0|Exit') || return 1
        case "$printer_selection" in
            1|K1C|k1c) PRINTER_MODEL=K1C; return 0 ;;
            2|generic|dev) PRINTER_MODEL=generic; return 0 ;;
            #3|K1|k1) PRINTER_MODEL=K1; return 0 ;;
            4|K1_2025|k1_2025) PRINTER_MODEL=K1_2025; return 0 ;;
            0|q) return 1 ;;
            *) printf 'Invalid selection. Try again.\n' ;;
        esac
    done
}
