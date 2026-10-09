#!/bin/sh
# install
register_action 'Moonraker and Nginx' "$S_ACTIONS/moonraker_nginx.sh" install 'K1C generic'
register_action 'nginx' "$S_ACTIONS/install-nginx.sh" install 'K1C generic'

register_action 'Entware' "$S_ACTIONS/entware.sh" install 'K1C'

# remove
register_action 'Moonraker and Nginx' "$S_ACTIONS/moonraker_nginx.sh" remove 'K1C generic'
register_action 'nginx' "$S_ACTIONS/remove-nginx.sh" remove 'K1C generic'

register_action 'Entware' "$S_ACTIONS/entware.sh" remove 'K1C'