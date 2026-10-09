#!/bin/sh

if [ "${TOOLKIT_READY:-}" != 1 ]; then
    printf 'Actions require the toolkit environment. Start main.sh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

ACTION_COMPONENT="Entware"

# Verify the required installation files before reporting success.
verify_entware_install(){
    if [ ! -f /opt/libexec/sftp-server ]; then
        error_msg "Entware install did not complete: openssh-sftp-server is missing, SFTP will not work."
        return 1
    fi
    if [ ! -s /opt/etc/opkg.conf ]; then
        error_msg "Entware install did not complete: /opt/etc/opkg.conf is missing or empty."
        return 1
    fi
    if ! grep -q '^src/gz ' /opt/etc/opkg.conf; then
        error_msg "Entware install did not complete: /opt/etc/opkg.conf has no package feed."
        return 1
    fi
    return 0
}


# Writes S48entware so /opt is mounted before camera services need Entware binaries.
# Removes the legacy S56entware startup script when migrating existing K1 2025 installs.
k1_2025_write_entware_init_script() {
    echo "Info: Installing Entware boot mount (S48entware, before S50 camera services)..."
    rm -f "$INITD_FOLDER/S56entware"
    {
        echo '#!/bin/sh'
        echo '# Creality Helper Script — persistent Entware /opt (must run before S50*).'
        echo "ENTWARE_IMG=\"$ENTWARE_OPT_MOUNT\""
        echo 'mkdir -p /opt'
        echo 'if ! grep -q " /opt " /proc/mounts; then'
        echo '  mount -o loop "$ENTWARE_IMG" /opt || exit 1'
        echo 'fi'
        echo 'if [ -f /opt/etc/init.d/rc.unslung ]; then'
        echo '  /opt/etc/init.d/rc.unslung start'
        echo 'fi'
        echo 'mkdir -p /usr/libexec'
        echo 'if [ ! -e /usr/libexec/sftp-server ] && [ -f /opt/libexec/sftp-server ]; then'
        echo '  ln -sf /opt/libexec/sftp-server /usr/libexec/sftp-server'
        echo 'fi'
        echo 'if ! grep -qF "/opt/bin:/opt/sbin" /etc/profile 2>/dev/null; then'
        echo '  echo '"'"'export PATH=/opt/bin:/opt/sbin:$PATH'"'"' >> /etc/profile'
        echo 'fi'
    } > "$INITD_FOLDER/S48entware"
    chmod +x "$INITD_FOLDER/S48entware"
}
k1_2025_opt_mount(){
    if [ -f "$ENTWARE_OPT_MOUNT" ]; then
        echo "Info: Existing /opt persistence file found. Skipping creation."
    else
        echo "Info: Creating /opt image for persistence..."
        dd if=/dev/zero of="$ENTWARE_OPT_MOUNT" bs=1M count=500
        mkfs.ext4 -F "$ENTWARE_OPT_MOUNT"
    fi

    k1_2025_write_entware_init_script

    echo "Info: Mounting Entware /opt for this session..."
    if ! grep -q " /opt " /proc/mounts; then
        mount -o loop "$ENTWARE_OPT_MOUNT" /opt
    fi
}

entware_install() {
    local yn installed=0
    if check_file "$ENTWARE_FILE"; then
        installed=1
    fi
    while true; do
        if [ "$installed" = 1 ]; then
            update_msg "$ACTION_COMPONENT" yn || return 1
        else
            install_msg "$ACTION_COMPONENT" yn || return 1
        fi
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                if [ "$installed" = 1 ]; then
                    echo -e "Info: Updating packages list..."
                    "$ENTWARE_FILE" update || return 1
                    echo -e "Info: Updating packages..."
                    "$ENTWARE_FILE" upgrade || return 1
                    ok_msg "Entware packages have been updated!"
                else
                    echo -e "Info: Running Entware installer..."
                    if [ "$PRINTER_MODEL" = "K1_2025" ]; then
                        k1_2025_opt_mount
                        $CURL -L "https://entware.diversion.ch/mipselsf-k3.4/installer/generic.sh" | sh
                        export PATH=/opt/bin:/opt/sbin:$PATH
                        opkg update

                        opkg install openssh-sftp-server
                        # Same guard as the S48entware boot script, which also creates this
                        # symlink: never point it at a file the install failed to produce.
                        mkdir -p /usr/libexec
                        if [ ! -e /usr/libexec/sftp-server ] && [ -f /opt/libexec/sftp-server ]; then
                            ln -sf /opt/libexec/sftp-server /usr/libexec/sftp-server
                        fi
                    else
                        chmod 755 "$ENTWARE_URL" || return 1
                        sh "$ENTWARE_URL" || return 1
                    fi
                    verify_entware_install || return 1
                    ok_msg "Entware has been installed successfully!"
                    echo -e "   Disconnect and reconnect SSH session, and you can now install packages with: ${yellow}opkg install <packagename>${white}"
                fi
                return 0
                ;;
            N|n)
                return 0
                ;;
            *)
                error_msg "Please select a correct choice!"
                ;;
        esac
    done
}

entware_remove() {
    local yn
    while true; do
        remove_msg "$ACTION_COMPONENT" yn || return 1
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                if [ "$PRINTER_MODEL" = "K1_2025" ]; then
                    echo -e "Info: Removing Entware boot scripts (K1 2025)..."
                    rm -f "$INITD_FOLDER/S48entware" "$INITD_FOLDER/S56entware"
                    if grep -q " /opt " /proc/mounts; then
                        umount /opt 2>/dev/null || true
                    fi
                else
                    echo -e "Info: Removing startup script..."
                    rm -f /etc/init.d/S50unslung
                    echo -e "Info: Removing directories..."
                    rm -rf /usr/data/opt
                fi
                if [ -L /opt ]; then
                    rm /opt
                    mkdir -p /opt
                    chmod 755 /opt
                fi
                echo -e "Info: Removing SFTP server symlink..."
                [ -L /usr/libexec/sftp-server ] && rm /usr/libexec/sftp-server
                echo -e "Info: Removing changes in system profile..."
                rm -f /etc/profile.d/entware.sh
                sed -i 's/\/opt\/bin:\/opt\/sbin:\/bin:/\/bin:/' /etc/profile
                ok_msg "Entware has been removed successfully!"
                return;;
            N|n)
                error_msg "Removal canceled!"
                return
                ;;
            *)
                error_msg "Please select a correct choice!"
                ;;
        esac
    done
}

case "${1:-}" in
    install|entware_install) entware_install ;;
    remove|entware_remove) entware_remove ;;
    *) printf 'Invalid %s action. Select %s under Install / Update or Remove in the toolkit menu.\n' "$ACTION_COMPONENT" "$ACTION_COMPONENT" >&2; return 1 2>/dev/null || exit 1 ;;
esac
