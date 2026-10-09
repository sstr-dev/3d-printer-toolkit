#!/bin/sh
start_moonraker() {
    set +e
    "$INITD_FOLDER"/S56moonraker_service start
    sleep 1
    set -e
}

stop_moonraker() {
    set +e
    "$INITD_FOLDER"/S56moonraker_service stop
    sleep 1
    set -e
}

restart_moonraker_action() {
    echo
    local yn
    while true; do
        restart_msg "Moonraker service" yn
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                stop_moonraker
                start_moonraker
                ok_msg "Moonraker service has been restarted successfully!"
                return;;
            N|n)
                error_msg "Restart canceled!"
                return;;
            *)
                error_msg "Please select a correct choice!";;
        esac
    done
}

start_nginx() {
    set +e
    "$INITD_FOLDER"/S50nginx start
    sleep 1
    set -e
}

stop_nginx() {
    set +e
    "$INITD_FOLDER"/S50nginx stop
    sleep 1
    set -e
}

restart_nginx() {
    set +e
    "$INITD_FOLDER"/S50nginx restart
    sleep 1
    set -e
}

restart_nginx_action() {
    echo
    local yn
    while true; do
        restart_msg "Nginx service" yn
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                stop_nginx
                start_nginx
                ok_msg "Nginx service has been restarted successfully!"
                return;;
            N|n)
                error_msg "Restart canceled!"
                return;;
            *)
                error_msg "Please select a correct choice!";;
        esac
    done
}

start_klipper() {
    set +e
    if [ -f "$INITD_FOLDER"/CS55klipper_service ]; then
        "$INITD_FOLDER"/CS55klipper_service start
    else
        "$INITD_FOLDER"/S55klipper_service start
    fi
    set -e
}

stop_klipper() {
    set +e
    if [ -f "$INITD_FOLDER"/CS55klipper_service ]; then
        "$INITD_FOLDER"/CS55klipper_service stop
    else
        "$INITD_FOLDER"/S55klipper_service stop
    fi
    set -e
}

restart_klipper() {
    set +e
    if [ -f "$INITD_FOLDER"/CS55klipper_service ]; then
        "$INITD_FOLDER"/CS55klipper_service restart
    else
        "$INITD_FOLDER"/S55klipper_service restart
    fi
    set -e
}

restart_klipper_action() {
    echo
    local yn
    while true; do
        restart_msg "Klipper service" yn
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                restart_klipper
                ok_msg "Klipper service has been restarted successfully!"
                return;;
            N|n)
                error_msg "Restart canceled!"
                return;;
            *)
                error_msg "Please select a correct choice!";;
        esac
    done
}
