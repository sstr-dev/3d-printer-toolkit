#!/bin/sh

# Fetch the configured update branch when the checkout is eligible.
# Sets: UPDATE_AVAILABLE, UPDATE_TARGET. Prints true when commits differ.
# Returns: 0, including when checking is unavailable or the fetch fails.
check_self_update() {
    UPDATE_AVAILABLE=0
    UPDATE_TARGET=''
    [ -d "$PROJECT_ROOT/.git" ] || return 0
    command -v git >/dev/null 2>&1 || return 0
    update_branch=$(git -C "$PROJECT_ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null) || return 0
    [ "$update_branch" = "${UPDATE_BRANCH:-main}" ] || return 0
    GIT_TERMINAL_PROMPT=0 git -C "$PROJECT_ROOT" \
        -c "http.lowSpeedLimit=${UPDATE_LOW_SPEED_LIMIT:-1}" \
        -c "http.lowSpeedTime=${UPDATE_LOW_SPEED_TIME:-15}" \
        fetch -q -- "${UPDATE_REMOTE:-origin}" "refs/heads/${UPDATE_BRANCH:-main}" >/dev/null 2>&1 || return 0
    UPDATE_TARGET=$(git -C "$PROJECT_ROOT" rev-parse --verify FETCH_HEAD 2>/dev/null) || return 0
    update_head=$(git -C "$PROJECT_ROOT" rev-parse --verify HEAD 2>/dev/null) || return 0
    if [ "$UPDATE_TARGET" != "$update_head" ]; then
        UPDATE_AVAILABLE=1
        printf 'true\n'
    fi
    return 0
}

# Apply UPDATE_TARGET with a fast-forward merge in a clean checkout.
# Clears UPDATE_AVAILABLE after success. Returns nonzero on failure.
apply_self_update() {
    update_changes=$(git -C "$PROJECT_ROOT" status --porcelain) || return 1
    if [ -n "$update_changes" ]; then
        printf 'Commit or stash local changes before updating.\n'
        return 1
    fi
    git -C "$PROJECT_ROOT" merge --ff-only "$UPDATE_TARGET" || return 1
    chmod +x "$PROJECT_ROOT/main.sh" || return 1
    UPDATE_AVAILABLE=0
    printf 'Update complete. Exit and restart the toolkit to load the new version.\n'
}

# Check for an update and ask before applying it.
# Returns: 0 when done/skipped, 130 on exit, or the update failure status.
update_menu() {
    check_self_update >/dev/null || return 0
    [ "$UPDATE_AVAILABLE" = 1 ] || return 0
    printf '\nA new toolkit version is available!\nUpdates may include bug fixes, important changes, and new features.\nPlease consider updating.\n\n'
    while true; do
        update_selection=$(menu_select 'A toolkit update is available' '1|Update now
0|Back
q|Exit') || return 130
        case "$update_selection" in
            1|y|Y)
                menu_run apply_self_update
                update_status=$?
                menu_pause || return 130
                return "$update_status" ;;
            0|b|n|N) return 0 ;;
            q) return 130 ;;
            *) printf 'Invalid selection. Try again.\n' ;;
        esac
    done
}
