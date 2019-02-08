#!/usr/bin/env bash

# enabling strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

# created files should always be group writable too
umask 0002

# allow the container to be started with `--user`
if [[ "$1" = 'bootstrap.sh' && "$(id -u)" = '0' ]]; then
  chown -R "$ZK_USER:0" $ZK_HOME/data $ZK_HOME/logs $ZK_HOME/conf
  # dropping privileges
  exec su-exec "$ZK_USER" "$0" "$@"
fi

exec "$@"
