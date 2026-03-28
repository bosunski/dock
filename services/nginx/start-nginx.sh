#!/bin/sh
set -e

watch_reload_requests() {
    mkdir -p /var/run/certbot

    while :; do
        if [ -f /var/run/certbot/reload-nginx ]; then
            rm -f /var/run/certbot/reload-nginx
            nginx -s reload || true
        fi

        sleep 5
    done
}

watch_reload_requests &

exec nginx -g 'daemon off;'
