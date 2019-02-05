#!/bin/bash

# enabling strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

# generic JVM settings you may want to add
JVM_OPTS=${JVM_OPTS:-""}
CLASSPATH=${CLASSPATH:-""}

# export JVM_HEAP_OPTS="-Xms512M -Xmx512M"
# export JMX_PORT=5555
# export JVM_GC_LOG=/var/log/gc.log

# write myid only if it doesn't exist
[ -f "$ZOODATADIR/myid" ] || echo "${ZK_SERVER_ID:-1}" > "$ZOODATADIR/myid"

# generate the config only if it doesn't exist
if [ ! -f "$ZOOCFGDIR/$ZOOCFG" ]; then
    cat <<-EOT >"$ZOOCFGDIR/$ZOOCFG"
clientPort=$ZK_CLIENT_PORT
dataDir=$ZOODATADIR
dataLogDir=$ZOOLOGSDIR

tickTime=$ZK_TICK_TIME
initLimit=$ZK_INIT_LIMIT
syncLimit=$ZK_SYNC_LIMIT

# whitelisting specific commands
4lw.commands.whitelist=stat, ruok
# disabling HTTP server
admin.enableServer=false
autopurge.snapRetainCount=$ZK_AUTOPURGE_SNAP_RETAIN_COUNT
autopurge.purgeInterval=$ZK_AUTOPURGE_PURGE_INTERVAL
maxClientCnxns=$ZK_MAX_CLIENT_CNXNS
standaloneEnabled=$ZK_STANDALONE_ENABLED

		EOT

    idx=1
    for s in $(echo ${ZK_SERVERS:-"localhost:2888:3888"} | tr ';' '\n'); do
        echo server.$((idx++))=$s >> "$ZOOCFGDIR/$ZOOCFG"
    done
fi

# generate log4j configuration
export LOG4J_CONF="$ZOOCFGDIR/log4j.properties"
cat <<-EOT >$LOG4J_CONF
log4j.rootLogger=${ZK_LOG_LEVEL:-"INFO"}, stdout

log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
# log4j.appender.stdout.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] %-5p [%C{1}] - %m%n
log4j.appender.stdout.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] %-5p [%C{2}] %m%n
# log4j.appender.stdout.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

EOT

# add specific loggers as defined by LOG4J_LOGGERS env variable
# e.g. LOG4J_LOGGERS="kafka.controller=WARN,kafka.foo.bar=DEBUG"
# will be transformed to:
# log4j.logger.kafka.controller=WARN, stdout
# log4j.logger.kafka.foo.bar=DEBUG, stdout
for s in $(echo $LOG4J_LOGGERS | tr ',' '\n'); do
    [ -z "${s##*=*}" ] && echo "log4j.logger.$s, stdout" >> $LOG4J_CONF
done


LIBPATH=($ZOOLIBDIR/*.jar)
for i in "${LIBPATH[@]}"; do
    CLASSPATH="$i:$CLASSPATH"
done
export CLASSPATH

echo "===[ Environment   ]==========================================================="
env
echo "===[ Configuration ]==========================================================="
cat "$ZOOCFGDIR/$ZOOCFG"
echo "===[ Zookeeper log ]==========================================================="

# Launch mode
exec jvm.sh org.apache.zookeeper.server.quorum.QuorumPeerMain "$ZOOCFGDIR/$ZOOCFG"
