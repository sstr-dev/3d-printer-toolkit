#!/bin/sh

menu_interactive() {
    [ "${MENU_INTERACTIVE:-0}" = 1 ] || return 1
    [ -t 0 ] && [ -t 2 ] && [ "${TERM:-dumb}" != dumb ]
}

menu_clear() {
    [ -t 2 ] && [ "${TERM:-dumb}" != dumb ] || return 0
    if command -v clear >/dev/null 2>&1; then
        clear >&2 2>/dev/null && return 0
    fi
    printf '%s\033[H\033[2J\033[3J' "$white" >&2
}

# Run a function or source a script in a subshell after clearing the screen.
# Arguments: target, followed by its arguments. Returns the target status.
menu_run() (
    menu_clear
    case "$1" in
        /*|./*|../*)
            menu_script=$1
            shift
            . "$menu_script"
            ;;
        *) "$@" ;;
    esac
)


# Styling helpers write to stderr so menu selections remain machine-readable.
hr() (
    line_width=${MENU_WIDTH:-64}
    case "$line_width" in ''|*[!0-9]*) line_width=64 ;; esac
    [ "$line_width" -ge 20 ] && [ "$line_width" -le 200 ] || line_width=64
    printf '%s' "${2:-+}" >&2
    while [ "$line_width" -gt 0 ]; do
        printf '%s' "${1:--}" >&2
        line_width=$((line_width - 1))
    done
    printf '%s\n' "${3:-+}" >&2
)

top_line() { hr "${MENU_OUTER_CHAR:-=}"; }
outer_line() { hr "${MENU_OUTER_CHAR:-=}"; }
inner_line() { hr "${MENU_INNER_CHAR:--}"; }

menu_line() (
    line_width=${MENU_WIDTH:-64}
    case "$line_width" in ''|*[!0-9]*) line_width=64 ;; esac
    [ "$line_width" -ge 20 ] && [ "$line_width" -le 200 ] || line_width=64
    line_width=$((line_width - 2))
    line_color=''
    line_reset=''
    if [ -t 2 ] && [ "${TERM:-dumb}" != dumb ] && [ -z "${NO_COLOR+x}" ]; then
        case "${2:-}" in
            white) line_color=$white ;;
            blue) line_color=$blue ;;
            cyan) line_color=$cyan ;;
            yellow) line_color=$yellow ;;
            green) line_color=$green ;;
            darkred) line_color=$darkred ;;
            red) line_color=$red ;;
            strikethrough) line_color=$strikethrough ;;
        esac
        [ -z "$line_color" ] || line_reset=$white
    fi
    printf '| %s%-*.*s%s |\n' "$line_color" "$line_width" "$line_width" "$1" "$line_reset" >&2
)
subtitle() {
    local menu_text1=$1
    local max_length=63
    local padding=$((max_length - ${#menu_text1}))
    printf "│ ${blue}${menu_text1}%-${padding}s${white}│\n" ''
}
info_line() {
    local status=$1
    local text=$2
    local color=$3
    local max_length=68
    local total_text_length=$(( ${#status} + ${#text} ))
    local padding=$((max_length - total_text_length))
    printf "│   $color${status} ${white}${text}%-${padding}s${white}│\n" ''
}
system_line() (
    case "${2:-}" in ''|Unavailable|unknown|N/A) return 0 ;; esac
    line_width=${MENU_WIDTH:-64}
    case "$line_width" in ''|*[!0-9]*) line_width=64 ;; esac
    [ "$line_width" -ge 20 ] && [ "$line_width" -le 200 ] || line_width=64
    line_color=${3:-green}
    printf '%-16s %s\n' "$1" "$2" |
        awk -v width="$((line_width - 2))" '{
            while (length($0) > width) {
                print substr($0, 1, width)
                $0 = substr($0, width + 1)
            }
            print
        }' |
        while IFS= read -r information_line; do
            menu_line "$information_line" "$line_color"
        done
)

menu_header() {
    top_line
    menu_line '3D Printer Toolkit'
    menu_line "$1 | ${PRINTER_MODEL:-unknown}"
    inner_line
}

menu_option() {
    if [ "${2:-}" = selected ]; then
        printf '\033[7m' >&2
        menu_line "> $1"
        printf '%s' "$white" >&2
    else
        menu_line "  $1"
    fi
}

# Print only the selected key to stdout; render the interface on stderr.
# Show a menu on stderr and print the selected key to stdout.
# Arguments: title, newline-separated key|label entries.
# Returns: 0 for a key, 130 on input failure or interrupted selection.
menu_select() (
    menu_title=$1
    menu_options=$2
    menu_clear
    if ! menu_interactive; then
        menu_header "$menu_title"
        menu_navigation=0
        while IFS='|' read -r menu_key menu_label; do
            case "$menu_key" in
                0|b|q)
                    if [ "$menu_navigation" = 0 ]; then
                        inner_line
                        menu_navigation=1
                    fi ;;
            esac
            menu_option "$menu_key) $menu_label"
        done <<EOF
$menu_options
EOF
        inner_line
        menu_line 'Type your choice and press Enter.'
        outer_line
        printf 'Select: ' >&2
        IFS= read -r menu_key || return 130
        printf '%s\n' "$menu_key"
        return 0
    fi

    menu_terminal=$(stty -g) || return 130
    trap 'stty "$menu_terminal"; printf "%s\033[?25h" "$white" >&2' 0
    trap 'exit 130' INT TERM HUP
    stty -echo -icanon min 1 time 0 || return 130
    printf '\033[?25l' >&2
    menu_position=1
    menu_escape=''
    while true; do
        printf '\033[H' >&2
        menu_header "$menu_title"
        menu_count=0
        while IFS='|' read -r menu_key menu_label; do
            menu_count=$((menu_count + 1))
            if [ "$menu_count" = "$menu_position" ]; then
                menu_selected=$menu_key
                menu_option "$menu_label" selected
            else
                menu_option "$menu_label"
            fi
        done <<EOF
$menu_options
EOF
        inner_line
        menu_line 'Up/Down or j/k: move   Enter: select'
        menu_line 'b: back   q: exit'
        outer_line
        while true; do
            menu_input=$(dd bs=1 count=1 2>/dev/null) || return 130
            case "$menu_input" in
                "$(printf '\033')") menu_escape=1; continue ;;
            esac
            if [ "$menu_escape" = 1 ]; then
                case "$menu_input" in '['|'O') menu_escape=2; continue ;; esac
                menu_escape=''
            elif [ "$menu_escape" = 2 ]; then
                menu_escape=''
                case "$menu_input" in A) menu_input=k ;; B) menu_input=j ;; *) continue ;; esac
            fi
            case "$menu_input" in
                k) menu_position=$((menu_position - 1)); [ "$menu_position" -gt 0 ] || menu_position=$menu_count; break ;;
                j) menu_position=$((menu_position + 1)); [ "$menu_position" -le "$menu_count" ] || menu_position=1; break ;;
                ''|"$(printf '\r')") printf '%s\n' "$menu_selected"; return 0 ;;
                q|b|[0-9]) printf '%s\n' "$menu_input"; return 0 ;;
            esac
        done
    done
)

menu_pause() {
    [ -t 0 ] || return 0
    printf '\nPress Enter to continue... '
    IFS= read -r menu_continue || return 130
}

install_msg() {
    read -p "${white} Are you sure you want to install ${green}${1} ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" $2
}

update_msg() {
    read -r -p "${white} ${green}${1}${white} is already installed. Update (${yellow}u${white}), remove (${yellow}r${white}), or cancel (${yellow}c${white}): ${yellow}" "$2"
}

remove_msg() {
    read -p "${white} Are you sure you want to remove ${green}${1} ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" $2
}

disable_msg() {
    read -p "${white} Are you sure you want to disable ${green}${1} ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" $2
}

restore_msg() {
    read -p "${white} Are you sure you want to restore ${green}${1} ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" $2
}

backup_msg() {
    read -p "${white} Are you sure you want to backup ${green}${1} ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" $2
}

restart_msg() {
    read -p "${white} Are you sure you want to restart ${green}${1} ${white}? (${yellow}y${white}/${yellow}n${white}): ${yellow}" $2
}

disabled_feature() {
    error_msg "Due to some compatibility issues, this feature is temporarily disabled!"
}

ok_msg() {
    echo
    echo -e "${white}${green} ✓ ${1}${white}"
    echo
}

warn_msg() {
    echo
    echo -e "${white}${yellow} ⚠ ${1}${white}"
    echo
}

error_msg() {
    echo
    echo -e "${white}${darkred} ✗ ${1}${white}"
    echo
}

check_folder_menu() {
    if check_folder "$1"; then
        echo -e "${green}✓"
    else
        printf '%s✗\n' "$red"
    fi
}

check_file_menu() {
    if check_file "$1"; then
        echo -e "${green}✓"
    else
        echo -e "${red}✗"
    fi
}

check_moonraker_component_menu() {
    if check_moonraker_component "${1:-}"; then
        echo -e "${green}✓"
    else
        echo -e "${red}✗"
    fi
}

check_folder_action() {
    if check_folder "$1"; then
        echo -e "[x] "
    else
        echo -e '[ ] '
    fi
}

check_file_action() {
    if check_file "$1"; then
        echo -e "[x] "
    else
        echo -e '[ ] '
    fi
}

check_moonraker_component_action() {
    if check_moonraker_component "${1:-}"; then
        echo -e "[x] "
    else
        echo -e '[ ] '
    fi
}

check_klipper_update_allow_action() {
    if [ -f "$INITD_FOLDER"/disabled.S55klipper_service ] || [ -f "$INITD_FOLDER"/disabled.CS55klipper_service ]; then
        echo -e '[ ] '
    else
        echo -e "[x] "
    fi
}

# Show registered actions in a category and run the selected target.
# Arguments: category, title. Each target receives the category as $1.
# Returns: 0 on Back, 130 on Exit or input failure.
show_action_menu() (
    category=$1
    title=$2
    reload_actions || return 1
    while true; do
        menu_options=''
        index=0
        while IFS='|' read -r number action_category label action; do
            [ "$action_category" = "$category" ] || continue
            index=$((index + 1))
            menu_options="${menu_options}${index}|${label}
"
        done <<EOF
$ACTIONS
EOF
        selection=$(menu_select "$title" "${menu_options}0|Back
q|Exit") || return 130
        case "$selection" in
            0|b) return 0 ;;
            q) return 130 ;;
        esac

        index=0
        selected_function=''
        while IFS='|' read -r number action_category label action; do
            [ "$action_category" = "$category" ] || continue
            index=$((index + 1))
            if [ "$selection" = "$index" ]; then
                selected_function=$action
                break
            fi
        done <<EOF
$ACTIONS
EOF
        if [ -n "$selected_function" ]; then
            menu_run "$selected_function" "$category"
            status=$?
            [ "$status" -ne 130 ] || return 130
            if [ "$status" -ne 0 ]; then
                printf 'Action failed (exit status %d).\n' "$status" >&2
            else
                reload_actions || return 1
            fi
            menu_pause || return 130
        else
            printf 'Invalid selection. Try again.\n'
        fi
    done
)
