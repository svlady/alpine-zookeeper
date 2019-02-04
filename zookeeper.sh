#!/bin/bash

# enabling strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
# IFS=$'\n\t'

# generic JVM settings you may want to add
JVM_OPTS=${JVM_OPTS:-""}
CLASSPATH=${CLASSPATH:-""}

# generate the config only if it doesn't exist
if [ ! -f "$ZOOCFGDIR/$ZOOCFG" ]; then
    cat <<-EOT >"$ZOOCFGDIR/$ZOOCFG"
clientPort=$ZK_PORT
dataDir=$ZOODATADIR
dataLogDir=$ZOOLOGSDIR

tickTime=$ZK_TICK_TIME
initLimit=$ZK_INIT_LIMIT
syncLimit=$ZK_SYNC_LIMIT

autopurge.snapRetainCount=$ZK_AUTOPURGE_SNAPRETAINCOUNT
autopurge.purgeInterval=$ZK_AUTOPURGE_PURGEINTERVAL
maxClientCnxns=$ZK_MAX_CLIENT_CNXNS
standaloneEnabled=$ZK_STANDALONE_ENABLED
		EOT

    for server in ${ZK_SERVERS:-"server.1=localhost:2888:3888;$ZK_PORT"}; do
        echo "$server" >> "$ZOOCFGDIR/$ZOOCFG"
    done
fi

# write myid only if it doesn't exist
[ -f "$ZOODATADIR/myid" ] || echo "${ZK_SERVER_ID:-1}" > "$ZOODATADIR/myid"

LIBPATH=($ZOOLIBDIR/*.jar)
for i in "${LIBPATH[@]}"; do
    CLASSPATH="$i:$CLASSPATH"
done

export CLASSPATH
export JVM_HEAP_OPTS="-Xms512M -Xmx512M"
# export JMX_PORT=5555
# export JVM_GC_LOG=/var/log/gc.log
export LOG4J_CONF="$ZOOCFGDIR/log4j.properties"

# Launch mode
exec jvm.sh org.apache.zookeeper.server.quorum.QuorumPeerMain "$ZOOCFGDIR/$ZOOCFG"
