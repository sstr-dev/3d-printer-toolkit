#!/bin/sh
#
# This program is based off of gitwatch @ https://github.com/gitwatch/gitwatch.git
# Copyright (C) 2013-2018  Patrick Lehner
#   with modifications and contributions by:
#   - Matthew McGowan
#   - Dominik D. Geyer
#   - Phil Thompson
#   - Dave Musicant
#   - Guislain Cyril
#
# Modified 2026 by Sascha (sstr-dev)

white=`echo -en "\033[m"`
yellow=`echo -en "\033[1;33m"`
green=`echo -en "\033[01;32m"`
darkred=`echo -en "\033[31m"`

INSTALL=0
VERIFY=0
ENV_FILE=""
INITD_FOLDER=${INITD_FOLDER:-/etc/init.d}
PAUSE=0
RESUME=0
STOP=0
REMOTE=""
BRANCH=""
TARGET=""
EVENTS="${EVENTS:-close_write,move,move_self,delete,create,modify}"
SLEEP_TIME=5
DATE_FMT="+%d-%m-%Y (%H:%M:%S)"
COMMITMSG="Auto-commit by Git Backup"
SKIP_IF_MERGING=0

# Function to print script help
shelp() {
    echo "Usage: $(basename "$0") [--install env-file | --verify env-file] [-p] [-r] [-s] -b branch -t target -g remote"
    echo "Options:"
    echo "  --install file  Install using the verified configuration"
    echo "  --verify file   Validate configuration without making changes"
    echo "  -p              Pause"
    echo "  -r              Resume"
    echo "  -s              Stop"
    echo "  -b branch       Specify branch for git push"
    echo "  -t target       Specify target directory or file to watch"
    echo "  -g remote       Specify remote for git push"
}

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --install|--verify|-b|-t|-g)
            if [ "$#" -lt 2 ] || [ -z "$2" ]; then
                echo "Error: $1 requires an argument." >&2
                exit 1
            fi
            case "$1" in
                --install) INSTALL=1; ENV_FILE=$2 ;;
                --verify) VERIFY=1; ENV_FILE=$2 ;;
                -b) BRANCH=$2 ;;
                -t) TARGET=$2 ;;
                -g) REMOTE=$2 ;;
            esac
            shift
            ;;
        -p) PAUSE=1 ;;
        -r) RESUME=1 ;;
        -s) STOP=1 ;;
        -h|--help) shelp; exit 0 ;;
        *) echo "Error: Invalid option." >&2; shelp; exit 1 ;;
    esac
    shift
done

# Check if more than one flag is used
if [ "$((INSTALL + VERIFY + PAUSE + RESUME + STOP))" -gt 1 ]; then
    echo "Error: Only one flag is allowed at a time."
    shelp
    exit 1
fi

load_configuration() {
    if [ ! -f "$ENV_FILE" ] || [ ! -r "$ENV_FILE" ]; then
        echo "Error: Configuration file is missing or unreadable." >&2
        return 1
    fi
    unset GIT_HOST AUTH_METHOD GIT_ACCOUNT REPO_PATH REMOTE_URL GIT_USER_NAME GIT_USER_EMAIL TARGET S_CONFIG_FOLDER ENTWARE_FILE
    while IFS= read -r entry || [ -n "$entry" ]; do
        case "$entry" in
            ''|'#'*) continue ;;
            *=*) ;;
            *) echo "Error: Invalid configuration entry." >&2; return 1 ;;
        esac
        key=${entry%%=*}
        value=${entry#*=}
        case "$key" in
            GIT_HOST|AUTH_METHOD|GIT_ACCOUNT|REPO_PATH|REMOTE_URL|GIT_USER_NAME|GIT_USER_EMAIL|TARGET|S_CONFIG_FOLDER|ENTWARE_FILE) ;;
            *) echo "Error: Unknown configuration key." >&2; return 1 ;;
        esac
        case "$value" in
            \'*\') value=${value#\'}; value=${value%\'} ;;
            *) echo "Error: Configuration values must be single-quoted." >&2; return 1 ;;
        esac
        value=$(printf '%s' "$value" | sed "s/'\\\\''/'/g")
        export "$key=$value"
    done < "$ENV_FILE"
}

verify_configuration() (
    load_configuration || return 1
    for entry in "GIT_HOST=${GIT_HOST-}" "AUTH_METHOD=${AUTH_METHOD-}" \
        "REPO_PATH=${REPO_PATH-}" "REMOTE_URL=${REMOTE_URL-}" \
        "GIT_USER_NAME=${GIT_USER_NAME-}" "GIT_USER_EMAIL=${GIT_USER_EMAIL-}" \
        "TARGET=${TARGET-}" "S_CONFIG_FOLDER=${S_CONFIG_FOLDER-}"; do
        if [ -z "${entry#*=}" ]; then
            echo "Error: Missing required value: ${entry%%=*}." >&2
            return 1
        fi
    done
    if [ "$AUTH_METHOD" != password ]; then
        echo "Error: Unsupported authentication method." >&2
        return 1
    fi
    case "$REMOTE_URL" in
        https://*:*@"$GIT_HOST"/"${REPO_PATH%.git}".git) ;;
        *) echo "Error: Remote URL does not match the configured HTTPS host and repository." >&2; return 1 ;;
    esac
    for directory in "$TARGET" "$S_CONFIG_FOLDER"; do
        if [ ! -d "$directory" ] || [ ! -r "$directory" ] || [ ! -w "$directory" ] || [ ! -x "$directory" ]; then
            echo "Error: A required configuration directory is missing or inaccessible." >&2
            return 1
        fi
    done
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: Git is required for backups." >&2
        return 1
    fi
    if ! command -v inotifywait >/dev/null 2>&1; then
        echo "Info: inotifywait is unavailable; backups will use polling."
    fi
    echo "Configuration verified successfully."
)

if [ "$VERIFY" = 1 ]; then
    verify_configuration
    exit $?
fi

# Pause, Resume, Stop flags
if [ "$PAUSE" = 1 ]; then
    echo "Info: Pausing automatic backups until the next reboot or manually restarted..."
    "$INITD_FOLDER/S52Git-Backup" stop || exit 1
    exit 0
elif [ "$STOP" = 1 ]; then
    echo "Info: Stopping automatic backups until manually restarted..."
    if [ -f "$INITD_FOLDER/S52Git-Backup" ];then
        "$INITD_FOLDER/S52Git-Backup" stop || exit 1
        mv "$INITD_FOLDER/S52Git-Backup" "$INITD_FOLDER/disabled.S52Git-Backup" || exit 1
    fi
    exit 0
elif [ "$RESUME" = 1 ]; then
    echo "Info: Resuming automatic backups..."
    if [ -f "$INITD_FOLDER/disabled.S52Git-Backup" ];then
        mv "$INITD_FOLDER/disabled.S52Git-Backup" "$INITD_FOLDER/S52Git-Backup" || exit 1
    fi
    "$INITD_FOLDER/S52Git-Backup" start || exit 1
    exit 0
elif [ "$INSTALL" = 1 ]; then
    verify_configuration || exit 1
    load_configuration || exit 1

    INSTALL_SOURCE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || exit 1
    INITD_FOLDER=${INITD_FOLDER:-/etc/init.d}
    BRANCH=${BRANCH:-main}
    if [ ! -r "$INSTALL_SOURCE/S52Git-Backup" ] || [ ! -r "$INSTALL_SOURCE/git-backup.cfg" ] || [ ! -d "$INITD_FOLDER" ]; then
        echo "Error: Installation files or service directory are missing." >&2
        exit 1
    fi
    git check-ref-format --branch "$BRANCH" >/dev/null 2>&1 || exit 1
    cd "$TARGET" || exit 1
    echo "Info: Initializing Git Backup repository..."
    git init || exit 1
    git config user.name "$GIT_USER_NAME" || exit 1
    git config user.email "$GIT_USER_EMAIL" || exit 1
    if git remote get-url origin >/dev/null 2>&1; then
        git remote set-url origin "$REMOTE_URL" || exit 1
    else
        git remote add origin "$REMOTE_URL" || exit 1
    fi
    if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
        git checkout "$BRANCH" || exit 1
    else
        git checkout -b "$BRANCH" || exit 1
    fi
    git add -A . || exit 1
    if ! git diff --cached --quiet || ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        git commit --allow-empty -m "Initial Backup" || exit 1
    fi
    # Avoid exposing credentials in Git's error output.
    if ! GIT_TERMINAL_PROMPT=0 git push -u origin "$BRANCH" >/dev/null 2>&1; then
        echo "Error: Initial backup push failed. Check credentials, repository access and branch history." >&2
        exit 1
    fi

    echo "Info: Installing Git Backup configuration and service..."
    ln -sf "$INSTALL_SOURCE/git-backup.cfg" "$S_CONFIG_FOLDER/git-backup.cfg" || exit 1
    if ! grep -q '^[[:space:]]*\[include 3dp-toolkit/git-backup.cfg\]' "$TARGET/printer.cfg"; then
        printf '\n[include 3dp-toolkit/git-backup.cfg]\n' >> "$TARGET/printer.cfg" || exit 1
    fi
    if [ -x "$INITD_FOLDER/S52Git-Backup" ]; then
        "$INITD_FOLDER/S52Git-Backup" stop || exit 1
    fi
    (
        printf '#!/bin/sh\n'
        for entry in "TARGET=$TARGET" "BRANCH=$BRANCH" "GIT_BACKUP_SCRIPT=$INSTALL_SOURCE/git-backup.sh"; do
            printf "%s='" "${entry%%=*}"
            printf '%s' "${entry#*=}" | sed "s/'/'\\\\''/g"
            printf "'\n"
        done
        tail -n +2 "$INSTALL_SOURCE/S52Git-Backup"
    ) > "$INITD_FOLDER/S52Git-Backup" || exit 1
    chmod 755 "$INITD_FOLDER/S52Git-Backup" "$INSTALL_SOURCE/git-backup.sh" || exit 1
    "$INITD_FOLDER/S52Git-Backup" start || exit 1
    #if [ -x "$INITD_FOLDER/S55klipper_service" ]; then
    #    "$INITD_FOLDER/S55klipper_service" restart || exit 1
    #fi
    echo "Git Backup has been installed successfully."
    exit 0
fi

# print all arguments to stderr
stderr() {
    echo "$@" >&2
}

# clean up at end of program, killing the remaining sleep process if it still exists
cleanup() {
    cleanup_status=$?
    trap - EXIT
    for child_pid in "${SLEEP_PID:-}" "${INOTIFY_PID:-}"; do
        if [ -n "$child_pid" ]; then
            kill "$child_pid" 2>/dev/null || :
            wait "$child_pid" 2>/dev/null || :
        fi
    done
    exit "$cleanup_status"
}

# Tests for the availability of a command
is_command() {
    command -v "$1" >/dev/null 2>&1
}

# Test whether or not current git directory has ongoing merge
is_merging () {
    [ -f "$(git rev-parse --git-dir)"/MERGE_HEAD ]
}


GIT="git"
RL="readlink"
INW="inotifywait"

# Check availability of selected binaries and die if not met
for cmd in "$GIT"; do
    is_command "$cmd" || {
        stderr "Error: Required command '$cmd' not found."
        exit 2
    }
done

SLEEP_PID="" # pid of timeout subprocess

trap "cleanup" EXIT # Stop only this backup process's children.
trap 'exit 0' INT TERM

# Expand the path to the target to absolute path
if [ "$(uname)" != "Darwin" ]; then
    IN=$($RL -f "$TARGET")
else
    if is_command "greadlink"; then
        IN=$(greadlink -f "$TARGET")
    else
        IN=$($RL -f "$TARGET")
        if [ $? -eq 1 ]; then
            echo "Info: Seems like your readlink doesn't support '-f'. Running without. Please 'brew install coreutils'."
            IN=$($RL "$TARGET")
        fi
    fi
fi

if [ -d "$TARGET" ]; then # if the target is a directory
    TARGETDIR=$(echo "$IN" | sed -e "s/\/*$//") # dir to CD into before using git commands: trim trailing slash, if any
    # construct inotifywait-commandline
    if [ "$(uname)" != "Darwin" ]; then
        INW_ARGS="-qmr -e $EVENTS $TARGETDIR"
    fi
    GIT_ADD="git add -A ." # add "." (CWD) recursively to index
    GIT_COMMIT_ARGS="-a"     # add -a switch to "commit" call just to be sure
else
    stderr "Error: The target is neither a regular file nor a directory."
    exit 3
fi

# CD into the right dir
cd "$TARGETDIR" || {
    stderr "Error: Can't change directory to '${TARGETDIR}'."
    exit 5
}

if [ -n "$REMOTE" ]; then        # are we pushing to a remote?
    if [ -z "$BRANCH" ]; then      # Do we have a branch set to push to ?
        PUSH_CMD="$GIT push $REMOTE" # Branch not set, push to remote without a branch
    else
        # check if we are on a detached HEAD
        if HEADREF=$($GIT symbolic-ref HEAD 2> /dev/null); then # HEAD is not detached
            PUSH_CMD="$GIT push $REMOTE ${HEADREF#refs/heads/}:$BRANCH"
        else # HEAD is detached
            PUSH_CMD="$GIT push $REMOTE $BRANCH"
        fi
    fi
else
    PUSH_CMD="" # if no remote is selected, make sure the push command is empty
fi

# Without inotifywait, commit only after the staged content stays unchanged.
if ! is_command "$INW"; then
    POLL_INTERVAL=${POLL_INTERVAL:-10}
    COMMIT_COOLDOWN=${COMMIT_COOLDOWN:-60}
    for duration in "$POLL_INTERVAL" "$COMMIT_COOLDOWN"; do
        case "$duration" in
            ''|*[!0-9]*|0*) stderr "Error: Polling durations must be positive integers."; exit 1 ;;
        esac
    done
    previous_tree=""
    quiet_seconds=0
    push_pending=0
    trap 'exit 0' INT TERM
    while true; do
        if ! is_merging; then
            STATUS=$(git status --porcelain) || exit 1
            if [ -n "$STATUS" ]; then
                git add -A . || exit 1
                current_tree=$(git write-tree) || exit 1
                if [ "$current_tree" != "$previous_tree" ]; then
                    previous_tree=$current_tree
                    quiet_seconds=0
                else
                    quiet_seconds=$((quiet_seconds + POLL_INTERVAL))
                fi
                if [ "$quiet_seconds" -ge "$COMMIT_COOLDOWN" ]; then
                    if git commit -m "$COMMITMSG"; then
                        push_pending=1
                        previous_tree=""
                        quiet_seconds=0
                    fi
                fi
            else
                previous_tree=""
                quiet_seconds=0
            fi
            if [ "$push_pending" = 1 ] && [ -n "$REMOTE" ]; then
                if [ -n "$BRANCH" ]; then
                    git push "$REMOTE" "HEAD:$BRANCH" && push_pending=0
                else
                    git push "$REMOTE" && push_pending=0
                fi
            fi
        fi
        sleep "$POLL_INTERVAL" &
        SLEEP_PID=$!
        wait "$SLEEP_PID"
        SLEEP_PID=""
    done
fi

# Track the watcher directly so stopping this backup cannot affect other watchers.
while true; do
    "$INW" -qr -t 10 -e "$EVENTS" "$TARGETDIR" >/dev/null 2>&1 &
    INOTIFY_PID=$!
    watcher_status=0
    wait "$INOTIFY_PID" || watcher_status=$?
    INOTIFY_PID=""
    case "$watcher_status" in
        0|2) ;;
        *) stderr "Error: inotifywait failed."; exit 1 ;;
    esac
    if is_merging; then
        continue
    fi
    STATUS=$(git status --porcelain) || exit 1
    if [ -n "$STATUS" ]; then
        git add -A . || exit 1
        git commit -m "$COMMITMSG" || continue
        if [ -n "$REMOTE" ]; then
            if [ -n "$BRANCH" ]; then
                git push "$REMOTE" "HEAD:$BRANCH"
            else
                git push "$REMOTE"
            fi
        fi
        sleep "$SLEEP_TIME" &
        SLEEP_PID=$!
        wait "$SLEEP_PID"
        SLEEP_PID=""
    fi
done
