#!/bin/sh
set -e
clear
trap 'echo -en "\033[m"' EXIT INT

PROJECT_ROOT="$(dirname "$(readlink -f "$0")")"
#PROJECT_ROOT="$(CDPATH= cd -P -- "$(dirname -- "$0")" && pwd)" || exit 1
readonly PROJECT_ROOT

# Load local settings before initializing modules and detecting the printer.
if [ -f "$PROJECT_ROOT/.env" ]; then
    . "$PROJECT_ROOT/.env" || exit 1
fi

# Command-line requests take precedence over .env settings.
for option in "$@"; do
    case "$option" in
        --interactive) MENU_INTERACTIVE=1 ;;
        *) printf 'Unknown option: %s\n' "$option" >&2; exit 1 ;;
    esac
done

unset TOOLKIT_ENV_READY

ACTIONS=''
ACTION_COUNT=0

# load modules
for script in "$PROJECT_ROOT"/modules/*.sh; do
    [ -f "$script" ] || continue
    . "$script" || exit 1
done

# Detect the environment and select a printer when detection is inconclusive.
detect_model || exit 1
select_printer || exit 0
set_paths || exit 1
TOOLKIT_READY=1
readonly TOOLKIT_READY
run_printer_selection_actions || exit 1

# Load menu actions.
reload_actions || exit 1


# Check for updates before showing the main menu.
UPDATE_AVAILABLE=0
if [ "${UPDATE_CHECK_ON_START:-1}" = 1 ]; then
    update_menu || { [ "$?" -ne 130 ] || exit 0; }
fi


while true; do
    menu_options='1|Install / Update
2|Remove
3|Tools
4|Customize
5|Info'
    if [ "$UPDATE_AVAILABLE" = 1 ]; then
        menu_options="$menu_options
6|Self Update"
    fi
    selection=$(menu_select 'Main menu' "$menu_options
0|Exit") || break
    case "$selection" in
        1) show_action_menu install 'Install / Update' || break ;;
        2) show_action_menu remove 'Remove' || break ;;
        3) show_action_menu tools 'Tools' || break ;;
        4) show_action_menu customize 'Customize' || break ;;
        5) show_action_menu info 'Info' || break ;;
        6)
            if [ "$UPDATE_AVAILABLE" = 1 ]; then
                update_menu || { [ "$?" -ne 130 ] || exit 0; }
            else
                printf 'Invalid selection. Try again.\n'
            fi
            ;;
        0|q) break ;;
        *) printf 'Invalid selection. Try again.\n' ;;
    esac
done
