#!/bin/sh
# Usage: sh test.sh [printer-config-directory]

failed=0
child=
target=${1:-${TARGET:-/usr/data/printer_data/config}}
pidfile=${PIDFILE:-/var/run/git-backup.pid}

check() {
    label=$1
    shift
    if "$@" >/dev/null 2>&1; then
        printf 'OK: %s\n' "$label"
    else
        printf 'FAIL: %s\n' "$label"
        failed=1
    fi
}

cleanup() {
    if [ -n "$child" ]; then
        kill "$child" 2>/dev/null || :
        wait "$child" 2>/dev/null || :
    fi
}
trap cleanup 0
trap 'exit 1' 1 2 3 15

printf 'Git Backup prerequisite checks (no installation or repository changes)\n'
printf 'Architecture: '
uname -m
printf 'Kernel: '
uname -r

for cmd in sh git start-stop-daemon grep tr sed awk od tail readlink stty \
    sleep dirname mkdir cp mv rm chmod ln; do
    check "$cmd available" command -v "$cmd"
done

check 'Git runs' git --version
check 'readlink -f supported' readlink -f /bin/sh
check 'grep -Fx -- supported' sh -c 'printf "test\n" | grep -Fx -- test'
check 'Shell handles SIGTERM' sh -c 'trap "exit 0" TERM; kill -TERM $$; exit 1'
check 'Process command line readable' test -r "/proc/$$/cmdline"
check "Backup directory exists: $target" test -d "$target"
check 'Backup directory readable' test -r "$target"
check 'Backup directory writable' test -w "$target"
check 'Backup directory searchable' test -x "$target"
pid_directory=$(dirname "$pidfile")
check "PID directory writable: $pid_directory" test -w "$pid_directory"
check 'PID directory searchable' test -x "$pid_directory"

if command -v start-stop-daemon >/dev/null 2>&1; then
    daemon_help=$(start-stop-daemon --help 2>&1) || :
    for option in S K q b m p x o s; do
        if printf '%s\n' "$daemon_help" | grep -Eq "(^|[[:space:],])-$option([[:space:],]|$)"; then
            printf 'OK: start-stop-daemon -%s\n' "$option"
        else
            printf 'FAIL: start-stop-daemon -%s not confirmed by help\n' "$option"
            failed=1
        fi
    done
fi

sleep 30 &
child=$!
if grep -Eq "(^| )$child( |$)" "/proc/$$/task/$$/children" 2>/dev/null; then
    echo 'OK: Child process detection through /proc children'
elif awk -v parent="$$" '$1 == "PPid:" && $2 == parent { found=1 } END { exit !found }' \
    "/proc/$child/status" 2>/dev/null; then
    echo 'OK: Child process detection through PPid fallback (reset supported)'
else
    echo 'FAIL: Cannot identify child processes for reset'
    failed=1
fi
cleanup
child=

if command -v inotifywait >/dev/null 2>&1; then
    echo 'OK: inotifywait available; event monitoring can be used'
else
    echo 'INFO: inotifywait unavailable; polling will be used (not an error)'
fi

echo
if [ "$failed" = 0 ]; then
    echo 'PASS: Prerequisites checked. Repository access and service operation still require an integration test.'
else
    echo 'FAIL: Resolve the failed checks before installing Git Backup.'
fi
exit "$failed"
