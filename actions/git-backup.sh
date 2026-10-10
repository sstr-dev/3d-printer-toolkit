#!/bin/sh

if [ "${TOOLKIT_READY:-}" != 1 ]; then
    printf 'Actions require the toolkit environment. Start main.sh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

setup_git_backup()
{
    local yn installed=0 request_restart=1
    if check_file "$GIT_BACKUP_FILE"; then
        installed=1
        request_restart=0
    fi
    while true; do
        if [ "$installed" = 1 ]; then
            remove_msg "Git Backup" yn || return 1
        else
            install_msg "Git Backup" yn || return 1
        fi
        case "${yn}" in
            Y|y)
                echo -e "${white}"

                if [ "$installed" = 1 ]; then
                    echo -e "Info: Stopping services..."
                    local git_backup_service="$INITD_FOLDER/S52Git-Backup"
                    if [ ! -f "$git_backup_service" ]; then
                        git_backup_service="$INITD_FOLDER/disabled.S52Git-Backup"
                    fi
                    if [ -x "$git_backup_service" ] &&
                        { "$git_backup_service" stop >/dev/null 2>&1 ||
                          "$git_backup_service" reset >/dev/null 2>&1; }; then
                        :
                    else
                        echo "Info: Service stop/reset unavailable or failed; falling back to killall..."
                        killall -q git-backup.sh || :
                        killall -q inotifywait || :
                    fi
                    echo -e "Info: Removing files..."
                    if [ -f "$INITD_FOLDER"/S52Git-Backup ];then
                        rm -f "$INITD_FOLDER"/S52Git-Backup
                    fi
                    if [ -f "$INITD_FOLDER"/disabled.S52Git-Backup ];then
                        rm -f "$INITD_FOLDER"/disabled.S52Git-Backup
                    fi
                    if [ -d "$KLIPPER_CONFIG_FOLDER"/.git ];then
                        rm -rf "$KLIPPER_CONFIG_FOLDER"/.git
                    fi
                    if [ -d "$S_BACKUP_FOLDER"/git-backup ];then
                        rm -rf "$S_BACKUP_FOLDER"/git-backup
                    fi
                    if grep -q "include 3dp-toolkit/git-backup" "$PRINTER_CFG" ; then
                        echo -e "Info: Removing Git Backup configurations in printer.cfg file..."
                        sed -i '/include 3dp-toolkit\/git-backup\.cfg/d' "$PRINTER_CFG"
                    else
                        echo -e "Info: Git Backup configurations are already removed in printer.cfg file..."
                    fi
                    if [ -f "$S_CONFIG_FOLDER"/git-backup.cfg ];then
                        rm -f "$S_CONFIG_FOLDER"/git-backup.cfg
                    fi
                    if [ -f "$ENTWARE_FILE" ]; then
                        echo -e "Info: Removing packages..."
                        set +e
                        "$ENTWARE_FILE" --autoremove remove inotifywait
                        set -e
                    fi

                    if [ ! -n "$(ls -A "$S_BACKUP_FOLDER")" ]; then
                        rm -rf "$S_BACKUP_FOLDER"
                    fi
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Git Backup has been removed successfully!"
                else
                    local git_host git_auth git_commit_name git_commit_email git_value git_input
                    local git_provider git_repo_mode git_account git_repo_path git_remote_url
                    local git_login git_password git_encoded_login git_encoded_password
                    git_account=
                    git_repo_mode=path
                    git_commit_name=$(git config --global --get user.name 2>/dev/null) || git_commit_name=
                    git_commit_email=$(git config --global --get user.email 2>/dev/null) || git_commit_email=
                    echo "Enter :q at any prompt to cancel."
                    while true; do
                        read -r -p "Git host [github/gitlab/custom]: " git_provider || return 1
                        [ "$git_provider" != :q ] || { error_msg "Installation canceled!"; return 0; }
                        case "$git_provider" in
                            github) git_host=github.com; break ;;
                            gitlab) git_host=gitlab.com; break ;;
                            custom)
                                read -r -p "Git hostname (HTTPS; without protocol or path): " git_host || return 1
                                [ "$git_host" != :q ] || { error_msg "Installation canceled!"; return 0; }
                                if printf '%s\n' "$git_host" | grep -Eq '^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$'; then
                                    break
                                fi
                                error_msg "Please enter a hostname without protocol or path!"
                                ;;
                            *) error_msg "Please select github, gitlab or custom!" ;;
                        esac
                    done
                    git_auth=password
                    while true; do
                        read -r -p "Git login username: " git_login || return 1
                        [ "$git_login" != :q ] || { error_msg "Installation canceled!"; return 0; }
                        if printf '%s\n' "$git_login" | grep -q '[^[:space:]]'; then
                            break
                        fi
                        error_msg "Please enter a login username!"
                    done
                    while true; do
                        printf 'Git password/token (hidden): ' >&2
                        git_password=$(
                            if [ -t 0 ]; then
                                git_terminal=$(stty -g) || exit 1
                                trap 'stty "$git_terminal"; printf "\n" >&2' 0
                                trap 'exit 1' 1 2 3 15
                                stty -echo || exit 1
                            fi
                            IFS= read -r git_input || exit 1
                            printf '%s' "$git_input"
                        ) || return 1
                        [ "$git_password" != :q ] || { error_msg "Installation canceled!"; return 0; }
                        [ -z "$git_password" ] || break
                        error_msg "Please enter a password or token!"
                    done
                    if [ "$git_provider" != custom ]; then
                        while true; do
                            read -r -p "Repository [personal/path (including group)]: " git_repo_mode || return 1
                            [ "$git_repo_mode" != :q ] || { error_msg "Installation canceled!"; return 0; }
                            case "$git_repo_mode" in
                                personal|path) break ;;
                                *) error_msg "Please select personal or path!" ;;
                            esac
                        done
                    fi
                    if [ "$git_repo_mode" = personal ]; then
                        while true; do
                            read -r -p "$git_provider account username (repository owner) [$git_login]: " git_input || return 1
                            [ "$git_input" != :q ] || { error_msg "Installation canceled!"; return 0; }
                            git_account=${git_input:-$git_login}
                            case "$git_account" in
                                ''|*[!a-zA-Z0-9_.-]*|[.-]*) error_msg "Please enter a valid account username!" ;;
                                *) break ;;
                            esac
                        done
                    fi
                    while true; do
                        if [ "$git_repo_mode" = personal ]; then
                            read -r -p "Repository name: " git_repo_path || return 1
                            [ "$git_repo_path" != :q ] || { error_msg "Installation canceled!"; return 0; }
                            case "$git_repo_path" in
                                */*) error_msg "Enter only the repository name!"; continue ;;
                            esac
                            git_repo_path="$git_account/$git_repo_path"
                        else
                            read -r -p "Repository path including owner/group (group[/subgroup]/repository): " git_repo_path || return 1
                            [ "$git_repo_path" != :q ] || { error_msg "Installation canceled!"; return 0; }
                        fi
                        if printf '%s\n' "$git_repo_path" | grep -Eq '^[a-zA-Z0-9_~-][a-zA-Z0-9._~-]*(/[a-zA-Z0-9_~-][a-zA-Z0-9._~-]*)+$'; then
                            break
                        fi
                        error_msg "Please enter a valid repository path including owner/group!"
                    done
                    git_encoded_login=$(printf '%s' "$git_login" | od -An -v -tx1 | awk '{ for (i = 1; i <= NF; i++) printf "%%%s", toupper($i) }')
                    git_encoded_password=$(printf '%s' "$git_password" | od -An -v -tx1 | awk '{ for (i = 1; i <= NF; i++) printf "%%%s", toupper($i) }')
                    git_remote_url="https://$git_encoded_login:$git_encoded_password@$git_host/${git_repo_path%.git}.git"
                    while true; do
                        read -r -p "Git commit author name (user.name) [$git_commit_name]: " git_input || return 1
                        [ "$git_input" != :q ] || { error_msg "Installation canceled!"; return 0; }
                        git_commit_name=${git_input:-$git_commit_name}
                        if printf '%s\n' "$git_commit_name" | grep -q '[^[:space:]]'; then
                            break
                        fi
                        error_msg "Please enter a commit author name!"
                        git_commit_name=
                    done
                    while true; do
                        read -r -p "Git commit author email (user.email) [$git_commit_email]: " git_input || return 1
                        [ "$git_input" != :q ] || { error_msg "Installation canceled!"; return 0; }
                        git_commit_email=${git_input:-$git_commit_email}
                        if printf '%s\n' "$git_commit_email" | grep -Eq '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'; then
                            break
                        fi
                        error_msg "Please enter a valid email address!"
                        git_commit_email=
                    done

                    if ! command -v inotifywait >/dev/null 2>&1; then
                        if [ ! -x "$ENTWARE_FILE" ]; then
                            while true; do
                                read -r -p "Entware is unavailable. Install Entware? [y/N] (:q to cancel): " git_input || return 1
                                case "$git_input" in
                                    y|Y)
                                        (set -- install; . "$S_ACTIONS/entware.sh") || error_msg "Entware installation failed."
                                        break ;;
                                    n|N|'') break ;;
                                    :q) error_msg "Installation canceled!"; return 0 ;;
                                    *) error_msg "Please select y, n or :q!" ;;
                                esac
                            done
                        fi
                        if [ -x "$ENTWARE_FILE" ]; then
                            export PATH="${ENTWARE_FILE%/*}:/opt/sbin:$PATH"
                            if ! command -v inotifywait >/dev/null 2>&1; then
                                while true; do
                                    read -r -p "Install inotifywait using Entware? [y/N] (:q to cancel): " git_input || return 1
                                    case "$git_input" in
                                        y|Y)
                                            if ! "$ENTWARE_FILE" update || ! "$ENTWARE_FILE" install inotifywait; then
                                                error_msg "inotifywait installation failed."
                                            fi
                                            break ;;
                                        n|N|'') break ;;
                                        :q) error_msg "Installation canceled!"; return 0 ;;
                                        *) error_msg "Please select y, n or :q!" ;;
                                    esac
                                done
                            fi
                        fi
                    fi
                    if ! command -v inotifywait >/dev/null 2>&1; then
                        echo "inotifywait is unavailable, so Git backups cannot receive file-change notifications."
                        echo "Polling checks for changes every 10 seconds and commits after 60 seconds without further changes."
                        read -r -p "Use polling for Git backups instead? [y/N] (:q to cancel): " git_input || return 1
                        case "$git_input" in
                            y|Y) ;;
                            *) error_msg "Installation canceled: Git Backup requires either polling or inotifywait to detect changes."; return 0 ;;
                        esac
                    fi
                    echo -e "Info: Creating directories..."
                    if [ ! -d "$S_CONFIG_FOLDER" ]; then
                        mkdir -p "$S_CONFIG_FOLDER"
                    fi
                    # .gitignore from templates/gitignore
                    if ! check_file "$PRINTER_DATA_CONFIG_FOLDER/.gitignore"; then
                        cp "$GIT_BACKUP_TEMPLATES_FOLDER"/gitignore "$PRINTER_DATA_CONFIG_FOLDER"/.gitignore
                    fi

                    if [ -f "$S_CONFIG_FOLDER"/git-backup.cfg ]; then
                        rm -f "$S_CONFIG_FOLDER"/git-backup.cfg
                    fi
                    if [ -d "$KLIPPER_CONFIG_FOLDER"/.git ]; then
                        rm -rf "$KLIPPER_CONFIG_FOLDER"/.git
                    fi
                    if [ -d "$S_BACKUP_FOLDER"/git-backup ]; then
                        rm -rf "$S_BACKUP_FOLDER"/git-backup
                    fi

                    echo -e "Info: Write .env file..."
                    mkdir -p "$S_BACKUP_FOLDER/git-backup" || return 1
                    (
                        umask 077
                        for git_value in "GIT_HOST=$git_host" "AUTH_METHOD=$git_auth" "GIT_ACCOUNT=$git_account" "REPO_PATH=$git_repo_path" "REMOTE_URL=$git_remote_url" "GIT_USER_NAME=$git_commit_name" "GIT_USER_EMAIL=$git_commit_email" \
                            "TARGET=$PRINTER_DATA_CONFIG_FOLDER" \
                            "S_CONFIG_FOLDER=$S_CONFIG_FOLDER" \
                            "ENTWARE_FILE=$ENTWARE_FILE"; do
                            printf "%s='" "${git_value%%=*}"
                            printf '%s' "${git_value#*=}" | sed "s/'/'\\\\''/g"
                            printf "'\n"
                        done > "$S_BACKUP_FOLDER/git-backup/.env"
                    ) || return 1

                    # verify with installer (git init and co)
                    # wenn repo bereits existiert: warnunen ob repo überschrieben werden soll
                    echo -e "Info: Verify configuration options..."
                    chmod 755 "$GIT_BACKUP_INSTALLER"
                    sh "$GIT_BACKUP_INSTALLER" --verify "$S_BACKUP_FOLDER/git-backup/.env" || return 1

                    echo -e "Info: Running Git Backup installer..."
                    sh "$GIT_BACKUP_INSTALLER" --install "$S_BACKUP_FOLDER/git-backup/.env" || return 1
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper

                fi
                return 0
                ;;
            N|n)
                error_msg "Installation canceled!"
                return
                ;;
            *)
                error_msg "Please select a correct choice!"
                ;;
        esac
    done
}

case "${1:-}" in
    tools|setup_git_backup) setup_git_backup ;;
    *) printf 'Invalid Git Backup action. Select Git Backup under Tools.\n' >&2; return 1 2>/dev/null || exit 1 ;;
esac
