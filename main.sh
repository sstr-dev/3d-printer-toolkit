#!/bin/sh
set -e

PROJECT_ROOT="$(dirname "$(readlink -f "$0")")"
#PROJECT_ROOT="$(CDPATH= cd -P -- "$(dirname -- "$0")" && pwd)" || exit 1
readonly PROJECT_ROOT

cli_printer=
cli_no_color=0
cli_debug=0
cli_no_update=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help)
            printf 'Usage: sh %s [OPTIONS]\n\n' "$0"
            printf '%s\n' \
                '  --help             Show this help and exit' \
                '  --version          Show the Git commit and exit' \
                '  --no-update-check  Skip the startup update check' \
                '  --printer MODEL    Select K1C, K1, K1_2025, or generic' \
                '  --no-color         Disable color output' \
                '  --debug            Trace shell commands to stderr'
            exit 0 ;;
        --version)
            toolkit_version=$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null) || toolkit_version=unknown
            printf '3D Printer Toolkit %s\n' "$toolkit_version"
            exit 0 ;;
        --printer)
            [ "$#" -ge 2 ] || { printf 'Missing MODEL for --printer\n' >&2; exit 1; }
            case "$2" in
                K1C|K1|K1_2025|generic) cli_printer=$2 ;;
                *) printf 'Unsupported printer model: %s\n' "$2" >&2; exit 1 ;;
            esac
            shift ;;
        --no-color) cli_no_color=1 ;;
        --debug) cli_debug=1 ;;
        --no-update-check) cli_no_update=1 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
    esac
    shift
done
readonly cli_printer cli_no_color cli_debug cli_no_update

# Load local settings before initializing modules and detecting the printer.
if [ -f "$PROJECT_ROOT/.env" ]; then
    . "$PROJECT_ROOT/.env" || exit 1
fi

# Command-line options take precedence over local settings.
[ -z "$cli_printer" ] || PRINTER_MODEL=$cli_printer
[ "$cli_no_update" -eq 0 ] || UPDATE_CHECK_ON_START=0
[ "$cli_no_color" -eq 0 ] || export NO_COLOR=1
[ "$cli_debug" -eq 0 ] || set -x

clear
if [ -z "${NO_COLOR+x}" ]; then
    trap 'printf "\033[m"' EXIT INT
fi

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
