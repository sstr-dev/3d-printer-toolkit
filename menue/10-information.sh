#!/bin/sh

show_project_information() {
    menu_line '3D printer applications, maintenance, and customization.'
    # TODO: Version, url
    
}

show_os_information() (
    detect_system_information

    system_line 'System:' "$OS_NAME"
    system_line 'Architecture:' "$ARCHITECTURE"
    system_line 'Hostname:' "${SYSTEM_HOSTNAME:-Unavailable}"
    system_line 'Kernel:' "${SYSTEM_KERNEL:-Unavailable}"
    system_line 'Uptime:' "${SYSTEM_UPTIME:-Unavailable}"
    system_line 'RAM:' "${SYSTEM_MEMORY:-Unavailable}"
    system_line 'Load average:' "${SYSTEM_LOAD:-Unavailable}"
    system_line 'Data disk:' "${SYSTEM_DISK:-Unavailable}"
)

show_printer_information() (
    detect_printer_information

    system_line 'Model:' "$PRINTER_MODEL"
    system_line 'Serial number:' "${PRINTER_SN:-Unavailable}"
    system_line 'Firmware:' "${PRINTER_VERSION:-Unavailable}"
    system_line 'IP addresses:' "${PRINTER_IPS:-Unavailable}"
    system_line 'Configuration:' "$CONFIG_DIR"
)

show_information() {
    top_line
    menu_line 'Printer' cyan
    inner_line
    show_printer_information
    inner_line
    menu_line 'OS' cyan
    inner_line
    show_os_information
    inner_line
    menu_line 'Project' cyan
    inner_line
    show_project_information
    outer_line
}

register_action 'Printer, OS and Project Info' show_information
