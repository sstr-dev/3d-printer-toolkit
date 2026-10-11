#!/bin/sh

detect_package_information() {
    # OPKG_PACKAGES=''
    NGINX_VERSION=''
    KLIPPER_VERSION=''
    MOONRAKER_VERSION=''
    FLUIDD_VERSION=''

    #if [ -x "${ENTWARE_FILE:-}" ]; then
    #    OPKG_PACKAGES=$("$ENTWARE_FILE" list-installed 2>/dev/null) || OPKG_PACKAGES=''
    #elif command -v opkg >/dev/null 2>&1; then
    #    OPKG_PACKAGES=$(opkg list-installed 2>/dev/null) || OPKG_PACKAGES=''
    #fi
    #OPKG_PACkAGES=$OPKG_PACKAGES

    if [ -x "${NGINX_BIN:-}" ]; then
        NGINX_VERSION=$("$NGINX_BIN" -v 2>&1) || NGINX_VERSION=''
    elif command -v nginx >/dev/null 2>&1; then
        NGINX_VERSION=$(nginx -v 2>&1) || NGINX_VERSION=''
    fi
    NGINX_VERSION=${NGINX_VERSION#nginx version: nginx/}

    for package_name in klipper moonraker fluidd; do
        case "$package_name" in
            klipper) package_folder=${KLIPPER_FOLDER:-${KLIPPER_KLIPPY_FOLDER:-${USR_SHARE:-/usr/share}/klipper/klippy}/..} ;;
            moonraker) package_folder=${MOONRAKER_FOLDER:+$MOONRAKER_FOLDER/moonraker} ;;
            fluidd) package_folder=${FLUIDD_FOLDER:-} ;;
        esac
        package_version=''
        if [ -n "$package_folder" ] && [ -d "$package_folder" ]; then
            if [ -e "$package_folder/.git" ]; then
                package_version=$(git -C "$package_folder" describe --tags --always --dirty 2>/dev/null) || package_version=''
            fi
            if [ -z "$package_version" ] && [ -r "$package_folder/.version" ]; then
                package_version=$(cat "$package_folder/.version" 2>/dev/null) || package_version=''
            fi
            if [ -z "$package_version" ]; then
                case "$package_name" in
                    klipper)
                        if [ -r "$package_folder/klippy/.version" ]; then
                            package_version=$(cat "$package_folder/klippy/.version" 2>/dev/null) || package_version=''
                        fi
                        ;;
                    fluidd)
                        if [ -r "$package_folder/release_info.json" ]; then
                            package_version=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$package_folder/release_info.json" 2>/dev/null) || package_version=''
                        fi
                        ;;
                esac
            fi
        fi
        case "$package_name" in
            klipper) KLIPPER_VERSION=$package_version ;;
            moonraker) MOONRAKER_VERSION=$package_version ;;
            fluidd) FLUIDD_VERSION=$package_version ;;
        esac
    done

    if [ -z "$KLIPPER_VERSION" ] && [ -n "${PRINTER_DATA_LOG_FOLDER:-}" ] && [ -r "$PRINTER_DATA_LOG_FOLDER/klippy.log" ]; then
        KLIPPER_VERSION=$(sed -n "s/^Git version: '\([^']*\)'.*/\1/p" "$PRINTER_DATA_LOG_FOLDER/klippy.log" 2>/dev/null | tail -n 1)
    fi
}
