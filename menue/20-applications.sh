#!/bin/sh

register_action 'Moonraker' "$S_ACTIONS/moonraker.sh" install 'K1C generic'
register_action 'nginx' "$S_ACTIONS/install-nginx.sh" install 'K1C generic'
register_action 'Moonraker' "$S_ACTIONS/moonraker.sh" remove 'K1C generic'
register_action 'nginx' "$S_ACTIONS/remove-nginx.sh" remove 'K1C generic'
