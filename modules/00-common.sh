#!/bin/sh

# Add a menu action, or skip it when the printer model does not match.
# Arguments: label, function/script, category (default: info), optional models.
# The menu passes the category to the selected target as $1.
# Updates: ACTIONS, ACTION_COUNT. Returns: 0 added/skipped, 1 invalid input.
register_action() {
    if [ "$#" -lt 2 ] || [ "$#" -gt 4 ] || [ -z "$1" ]; then
        printf 'An action requires a label and an existing function or script.\n' >&2
        return 1
    fi
    case "$1" in
        *'|'*|*'
'*) printf 'Action labels cannot contain pipes or newlines.\n' >&2; return 1 ;;
    esac
    case "$2" in
        *'|'*|*'
'*) printf 'Action targets cannot contain pipes or newlines.\n' >&2; return 1 ;;
        /*|./*|../*)
            if [ ! -f "$2" ] || [ ! -r "$2" ]; then
                printf 'Action script is not readable: %s\n' "$2" >&2
                return 1
            fi ;;
        ''|[0-9]*|*[!a-zA-Z0-9_]*)
            printf 'Invalid action function name or script path.\n' >&2
            return 1 ;;
        *)
            if ! command -v "$2" >/dev/null 2>&1; then
                printf 'Action function does not exist: %s\n' "$2" >&2
                return 1
            fi ;;
    esac

    case "${3:-info}" in
        install|remove|info|update|tools|customize) ;;
        *) printf 'Invalid action category.\n' >&2; return 1 ;;
    esac

    if [ -n "${4:-}" ]; then
        case " $4 " in
            *" ${PRINTER_MODEL} "*) ;;
            *) return 0 ;;
        esac
    fi

    ACTION_COUNT=$((ACTION_COUNT + 1))
    ACTIONS="${ACTIONS}${ACTION_COUNT}|${3:-info}|$1|$2
"
}
