#!/bin/sh

set -eu

if command -v setfacl >/dev/null 2>&1 && [ -S /var/run/docker.sock ]; then
    setfacl -m u:node:rw /var/run/docker.sock || true
    setfacl -m m:rw /var/run/docker.sock || true
fi

chmod 1777 /tmp || true

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
