#!/bin/sh

if [ "${TOOLKIT_READY:-}" != 1 ]; then
    printf 'Actions require the toolkit environment. Start main.sh.\n' >&2
    return 1 2>/dev/null || exit 1
fi

ACTION_COMPONENT="Improved Shapers Calibrations"


improved_shapers_install() {
    if [ -d "$IMP_SHAPERS_FOLDER" ]; then
        error_msg "Improved Shapers Calibrations are already installed!"
    elif [ -d "$GUPPY_SCREEN_FOLDER" ]; then
        error_msg "Guppy Screen already has these features!"
    elif [ ! -f "$KLIPPER_SHELL_FILE" ]; then
        error_msg "Klipper Gcode Shell Command is needed, please install it first!"
    else
        local yn
        while true; do
            install_msg "Improved Shapers Calibrations" yn
            case "${yn}" in
                Y|y)
                    echo -e "${white}"
                    echo -e "Info: Backing up original file..."
                    if [ ! -d "$S_BACKUP_FOLDER"/improved-shapers ]; then
                        mkdir -p "$S_BACKUP_FOLDER"/improved-shapers
                    fi
                    if [ ! -f "$S_BACKUP_FOLDER"/ft2font.cpython-38-mipsel-linux-gnu.so ]; then
                        mv /usr/lib/python3.8/site-packages/matplotlib/ft2font.cpython-38-mipsel-linux-gnu.so "$S_BACKUP_FOLDER"/improved-shapers
                    fi
                    echo -e "Info: Linking files..."
                    ln -sf "$IMP_SHAPERS_URL"/calibrate_shaper_config.py "$KLIPPER_EXTRAS_FOLDER"/calibrate_shaper_config.py
                    if [ ! -d "/usr/lib/python3.8/site-packages/matplotlib-2.2.3-py3.8.egg-info" ]; then
                        echo -e "Info: mathplotlib ft2font module is not replaced. PSD graphs might not work..."
                    else
                        echo -e "Info: Replacing mathplotlib ft2font module to generate PSD graphs..."
                        cp "$IMP_SHAPERS_URL"/ft2font.cpython-38-mipsel-linux-gnu.so /usr/lib/python3.8/site-packages/matplotlib/ft2font.cpython-38-mipsel-linux-gnu.so
                    fi
                    if [ -f "$S_CONFIG_FOLDER"/improved-shapers ]; then
                        rm -rf "$S_CONFIG_FOLDER"/improved-shapers
                    fi
                    if [ ! -d "$S_CONFIG_FOLDER"/improved-shapers/scripts ]; then
                        mkdir -p "$S_CONFIG_FOLDER"/improved-shapers/scripts
                    fi
                    cp "$IMP_SHAPERS_URL"/scripts/*.py "$S_CONFIG_FOLDER"/improved-shapers/scripts
                    ln -sf "$IMP_SHAPERS_URL"/improved-shapers.cfg "$S_CONFIG_FOLDER"/improved-shapers/improved-shapers.cfg
                    if grep -q 'variable_autotune_shapers:' "$MACROS_CFG" ; then
                        echo -e "Info: Disabling [gcode_macro AUTOTUNE_SHAPERS] configurations in gcode_macro.cfg file..."
                        sed -i 's/variable_autotune_shapers:/#&/' "$MACROS_CFG"
                    else
                        echo -e "Info: [gcode_macro AUTOTUNE_SHAPERS] configurations are already disabled in gcode_macro.cfg file..."
                    fi
                    if [ "$PRINTER_MODEL" = "K1C" ]; then
                        if grep -q '\[gcode_macro INPUTSHAPER\]' "$MACROS_CFG" ; then
                            echo -e "Info: Replacing [gcode_macro INPUTSHAPER] configurations in gcode_macro.cfg file..."
                            sed -i 's/SHAPER_CALIBRATE AXIS=y/SHAPER_CALIBRATE/' "$MACROS_CFG"
                        else
                            echo -e "Info: [gcode_macro INPUTSHAPER] configurations are already replaced in gcode_macro.cfg file..."
                        fi
                    fi
                    if grep -q "include 3dp-toolkit/improved-shapers/improved-shapers" "$PRINTER_CFG" ; then
                        echo -e "Info: Improved Shapers Calibration configurations are already enabled in printer.cfg file..."
                    else
                        echo -e "Info: Adding Improved Shapers Calibration configurations in printer.cfg file..."
                        sed -i '/\[include printer_params\.cfg\]/a \[include 3dp-toolkit/improved-shapers/improved-shapers\.cfg\]' "$PRINTER_CFG"
                    fi
                    echo -e "Info: Restarting Moonraker service..."
                    stop_moonraker
                    start_moonraker
                    echo -e "Info: Restarting Klipper service..."
                    restart_klipper
                    ok_msg "Improved Shapers Calibrations have been installed successfully!"
                    return;;
                N|n)
                    error_msg "Installation canceled!"
                    return;;
                *)
                    error_msg "Please select a correct choice!";;
            esac
        done
    fi
}

improved_shapers_remove() {
    local yn
    while true; do
        remove_msg "Improved Shapers Calibrations" yn
        case "${yn}" in
            Y|y)
                echo -e "${white}"
                if [ -f "$S_BACKUP_FOLDER"/improved-shapers/ft2font.cpython-38-mipsel-linux-gnu.so ]; then
                    echo -e "Info: Restoring original file..."
                    mv "$S_BACKUP_FOLDER"/improved-shapers/ft2font.cpython-38-mipsel-linux-gnu.so /usr/lib/python3.8/site-packages/matplotlib
                    rm -rf "$S_BACKUP_FOLDER"/improved-shapers
                fi
                if [ ! -n "$(ls -A "$S_BACKUP_FOLDER")" ]; then
                    rm -rf "$S_BACKUP_FOLDER"
                fi
                echo -e "Info: Removing files..."
                rm -rf "$IMP_SHAPERS_FOLDER"
                rm -f "$KLIPPER_EXTRAS_FOLDER"/calibrate_shaper_config.py
                rm -f "$KLIPPER_EXTRAS_FOLDER"/calibrate_shaper_config.pyc
                if grep -q "#variable_autotune_shapers:" "$MACROS_CFG"; then
                    echo -e "Info: Restoring [gcode_macro AUTOTUNE_SHAPERS] configurations in gcode_macro.cfg file..."
                    sed -i 's/#variable_autotune_shapers:/variable_autotune_shapers:/' "$MACROS_CFG"
                else
                    echo -e "Info: [gcode_macro AUTOTUNE_SHAPERS] configurations are already restored in gcode_macro.cfg file..."
                fi
                if [ "$PRINTER_MODEL" = "K1C" ]; then
                    if grep -q '\[gcode_macro INPUTSHAPER\]' "$MACROS_CFG" ; then
                        echo -e "Info: Restoring [gcode_macro INPUTSHAPER] configurations in gcode_macro.cfg file..."
                        sed -i 's/SHAPER_CALIBRATE/SHAPER_CALIBRATE AXIS=y/' "$MACROS_CFG"
                    else
                        echo -e "Info: [gcode_macro INPUTSHAPER] configurations are already restored in gcode_macro.cfg file..."
                    fi
                fi
                if grep -q "include 3dp-toolkit/improved-shapers/improved-shapers" "$PRINTER_CFG" ; then
                    echo -e "Info: Removing Improved Shapers Calibrations in printer.cfg file..."
                    sed -i '/include 3dp-toolkit\/improved-shapers\/improved-shapers\.cfg/d' "$PRINTER_CFG"
                else
                    echo -e "Info: Improved Shapers Calibrations are already removed in printer.cfg file..."
                fi
                if [ ! -n "$(ls -A "$S_CONFIG_FOLDER")" ]; then
                    rm -rf "$S_CONFIG_FOLDER"
                fi
                echo -e "Info: Restarting Moonraker service..."
                stop_moonraker
                start_moonraker
                echo -e "Info: Restarting Klipper service..."
                restart_klipper
                ok_msg "Improved Shapers Calibrations have been removed successfully!"
                return;;
            N|n)
                error_msg "Deletion canceled!"
                return;;
            *)
                error_msg "Please select a correct choice!";;
        esac
    done
}

case "${1:-}" in
    install|improved_shapers_install) improved_shapers_install ;;
    remove|improved_shapers_remove) improved_shapers_remove ;;
    *) printf 'Invalid %s action. Select %s under Install / Update or Remove in the toolkit menu.\n' "$ACTION_COMPONENT" "$ACTION_COMPONENT" >&2; return 1 2>/dev/null || exit 1 ;;
esac
