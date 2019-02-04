#!/bin/bash

set -e

# created files should always be group writable too
umask 0002

# Allow the container to be started with `--user`
if [[ "$1" = 'zookeeper.sh' && "$(id -u)" = '0' ]]; then
    chown -R "$ZK_USER:0" "$ZOODATADIR" "$ZOOLOGSDIR" "$ZOOCFGDIR"
    exec su-exec "$ZK_USER" "$0" "$@"
fi

exec "$@"