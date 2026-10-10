#!/bin/sh

if [ "${TOOLKIT_READY:-}" != 1 ]; then
    printf 'Actions require the toolkit environment. Start main.sh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

ACTION_COMPONENT="Klipper Adaptive Meshing & Purging"


kamp_install() {
    local yn installed=0
    if check_file "$ENTWARE_FILE"; then
        installed=1
    fi
    while true; do
        if [ "$installed" = 1 ]; then
            update_msg "$ACTION_COMPONENT" yn || return 1
            case "$yn" in
                U|u|update) yn=y ;;
                R|r|remove) kamp_remove confirmed; return $? ;;
                C|c|cancel) return 0 ;;
                *) error_msg "Please select update, remove, or cancel!"; continue ;;
            esac
        else
            install_msg "$ACTION_COMPONENT" yn || return 1
        fi
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                if [ "$installed" = 1 ]; then
                    warn_msg "$ACTION_COMPONENT update is not implemented yet."
                    return 1
                else
                    if [ -d "$S_CONFIG_FOLDER"/KAMP ]; then
                        rm -rf "$S_CONFIG_FOLDER"/KAMP
                    fi
                    if [ -f "$S_CONFIG_FOLDER"/KAMP_Settings.cfg ]; then
                        rm -f "$S_CONFIG_FOLDER"/KAMP_Settings.cfg
                    fi
                    echo -e "Info: Creating directories..."
                    if [ ! -d "$S_CONFIG_FOLDER" ]; then
                        mkdir -p "$S_CONFIG_FOLDER"
                    fi
                    mkdir -p "$S_CONFIG_FOLDER"/KAMP
                    echo -e "Info: Linking files..."
                    ln -sf "$KAMP_URL"/Adaptive_Meshing.cfg "$KAMP_FOLDER"/Adaptive_Meshing.cfg
                    ln -sf "$KAMP_URL"/Line_Purge.cfg "$KAMP_FOLDER"/Line_Purge.cfg
                    ln -sf "$KAMP_URL"/Prusa_Slicer.cfg "$KAMP_FOLDER"/Prusa_Slicer.cfg
                    ln -sf "$KAMP_URL"/Smart_Park.cfg "$KAMP_FOLDER"/Smart_Park.cfg
                    ln -sf "$KAMP_URL"/Start_Print.cfg "$KAMP_FOLDER"/Start_Print.cfg
                    cp "$KAMP_URL"/KAMP_Settings.cfg "$KAMP_FOLDER"/KAMP_Settings.cfg
                    if [ -L "$VIRTUAL_PINS_FILE" ]; then
                        local yn_virtual_pins
                        printf 'Virtual pins symbolic link already exists. Overwrite? (y/N): '
                        IFS= read -r yn_virtual_pins || return 1
                        case "$yn_virtual_pins" in
                            Y|y) ln -sfn "$VIRTUAL_PINS_URL" "$VIRTUAL_PINS_FILE" ;;
                        esac
                    else
                        ln -sf "$VIRTUAL_PINS_URL" "$VIRTUAL_PINS_FILE"
                    fi

                    if grep -q "[virtual_pins]" "$PRINTER_CFG" ; then
                        echo -e "Info: Adding [virtual_pins] configuration in printer.cfg file..."
                        sed -i '/\[include sensorless.cfg\]/i [virtual_pins]' "$PRINTER_CFG"
                    else
                        echo -e "Info: [virtual_pins] configuration is already enabled in printer.cfg file..."
                    fi
                    if grep -q "include 3dp-toolkit/KAMP/KAMP_Settings" "$PRINTER_CFG" ; then
                        echo -e "Info: KAMP configurations are already enabled in printer.cfg file..."
                    else
                        echo -e "Info: Adding KAMP configurations in printer.cfg file..."
                        sed -i '/\[include printer_params\.cfg\]/a [include 3dp-toolkit/KAMP/KAMP_Settings.cfg]' "$PRINTER_CFG"
                    fi
                    if grep -q "\[gcode_macro START_PRINT\]" "$MACROS_CFG" ; then
                        echo -e "Info: Disabling [gcode_macro START_PRINT] in gcode_macro.cfg file..."
                        sed -i '/\[gcode_macro START_PRINT\]/,/^\s*CX_PRINT_DRAW_ONE_LINE/ { /^\s*$/d }' "$MACROS_CFG"
                        sed -i '/^\[gcode_macro START_PRINT\]/,/^\s*$/ s/^\(\s*\)\([^#]\)/#\1\2/' "$MACROS_CFG"
                    else
                        echo -e "Info: [gcode_macro START_PRINT] is already disabled in gcode_macro.cfg file..."
                    fi
                    echo
                    local yn_prusa
                    while true; do
                        read -p " Do you want to enable needed macros for PrusaSlicer? (${yellow}y${white}/${yellow}n${white}): ${yellow}" yn_prusa
                        case "${yn_prusa}" in
                            Y|y)
                                echo -e "${white}"
                                if grep -q "#\[include Prusa_Slicer.cfg\]" "$KAMP_FOLDER"/KAMP_Settings.cfg ; then
                                    echo -e "Info: Enabling [include Prusa_Slicer.cfg] in KAMP_Settings.cfg file..."
                                    sed -i 's/^#\[include Prusa_Slicer\.cfg\]/[include Prusa_Slicer.cfg]/' "$KAMP_FOLDER"/KAMP_Settings.cfg
                                else
                                    echo -e "Info: [include Prusa_Slicer.cfg] is already enabled in KAMP_Settings.cfg file..."
                                fi
                                break;;
                            N|n)
                                echo -e "${white}"
                                break;;
                            *)
                                error_msg "Please select a correct choice!";;
                        esac
                    done
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Klipper Adaptive Meshing & Purging has been installed successfully!"
                    echo -e "   Make sure Label Objects setting is enabled in your slicer."
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

kamp_remove() {
    local yn
    while true; do
        if [ "${1:-}" = confirmed ]; then
            yn=y
        else
            remove_msg "$ACTION_COMPONENT" yn || return 1
        fi
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                echo -e "Info: Removing files..." 
                rm -rf "$S_CONFIG_FOLDER"/KAMP
                rm -f "$KLIPPER_EXTRAS_FOLDER"/virtual_pins.py 
                rm -f "$KLIPPER_EXTRAS_FOLDER"/virtual_pins.pyc
                if grep -q "[virtual_pins]" "$PRINTER_CFG" ; then
                    echo -e "Info: Removing [virtual_pins] configuration in printer.cfg file..."
                    sed -i '/\[virtual_pins\]/d' "$PRINTER_CFG"
                else
                    echo -e "Info: [virtual_pins] configuration is already removed in printer.cfg file..."
                fi
                if grep -q "include 3dp-toolkit/KAMP/KAMP_Settings" "$PRINTER_CFG" ; then
                    echo -e "Info: Removing KAMP configurations in printer.cfg file..."
                    sed -i '/include 3dp-toolkit\/KAMP\/KAMP_Settings\.cfg/d' "$PRINTER_CFG"
                else
                    echo -e "Info: KAMP configurations are already removed in printer.cfg file..."
                fi
                if grep -q "#\[gcode_macro START_PRINT\]" "$MACROS_CFG" ; then
                    echo -e "Info: Enabling [gcode_macro START_PRINT] in gcode_macro.cfg file..."
                    sed -i -e 's/^\s*#[[:space:]]*\[gcode_macro START_PRINT\]/[gcode_macro START_PRINT]/' -e '/^\[gcode_macro START_PRINT\]/,/^\s*$/ s/^\(\s*\)#/\1/' "$MACROS_CFG"
                else
                    echo -e "Info: [gcode_macro START_PRINT] is already enabled in gcode_macro.cfg file..."
                fi
                if [ ! -n "$(ls -A "$S_CONFIG_FOLDER")" ]; then
                    rm -rf "$S_CONFIG_FOLDER"
                fi
                echo -e "Info: Restarting Klipper service..."
                restart_klipper
                ok_msg "Klipper Adaptive Meshing & Purging has been removed successfully!"
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
    install|kamp_install) kamp_install ;;
    remove|kamp_remove) kamp_remove ;;
    *) printf 'Invalid %s action. Select %s under Install / Update or Remove in the toolkit menu.\n' "$ACTION_COMPONENT" "$ACTION_COMPONENT" >&2; return 1 2>/dev/null || exit 1 ;;
esac
