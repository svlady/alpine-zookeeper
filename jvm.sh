#!/bin/bash

# enabling strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
# IFS=$'\n\t'

# # created files should always be group writable too
# umask 0002

# generic JVM settings you may want to add
JVM_OPTS=${JVM_OPTS:-""}
CLASSPATH=${CLASSPATH:-""}

### which java to use
if [ -z "${JAVA_HOME:-}" ]; then
  JAVA="java"
else
  JAVA="$JAVA_HOME/bin/java"
fi

# Remove a possible colon prefix from the classpath (happens at lines like `CLASSPATH="$CLASSPATH:$file"` when CLASSPATH is blank)
CLASSPATH=${CLASSPATH#:}

if [ -z "$CLASSPATH" ] ; then
    echo "Classpath is empty. Exiting..."
    exit 1
fi

# JVM heap options
JVM_HEAP_OPTS=${JVM_HEAP_OPTS:-"-Xms256M -Xmx256M"}

# JVM performance options
JVM_PERF_OPTS=${JVM_PERF_OPTS:-"-server -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:+ExplicitGCInvokesConcurrent -Djava.awt.headless=true"}

# JMX settings
JMX_OPTS=${JMX_OPTS:-"-Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"}

if [ ${JMX_PORT:-""} ]; then
    JMX_OPTS="$JMX_OPTS -Dcom.sun.management.jmxremote.port=$JMX_PORT "
fi

# Log4j settings
if [ ${LOG4J_CONF:-""} ]; then
    JMX_OPTS="$JMX_OPTS -Dlog4j.configuration=file:${LOG4J_CONF} "
fi

# add debug options if enabled
if [ ${JVM_DEBUG:-""} ]; then
    JVM_DEBUG_PORT=${JVM_DEBUG_PORT:-"5005"}

    # Use the defaults if JAVA_DEBUG_OPTS was not set
    JVM_DEBUG_OPTS=${JVM_DEBUG_OPTS:-"-agentlib:jdwp=transport=dt_socket,server=y,suspend=${JVM_DEBUG_SUSPEND_FLAG:-n},address=$JVM_DEBUG_PORT"}

    JVM_OPTS="$JVM_DEBUG_OPTS $JVM_OPTS"
fi


# add GC options if enabled
if [ ${JVM_GC_LOG:-} ]; then
    # The first segment of the version number, which is '1' for releases before Java 9
    # it then becomes '9', '10', ... Some examples of the first line of `java --version`:
    #   8 -> java version "1.8.0_152"
    #   9.0.4 -> java version "9.0.4"
    #   10 -> java version "10" 2018-03-20
    #   10.0.1 -> java version "10.0.1" 2018-04-17
    JAVA_MAJOR_VERSION=$($JAVA -version 2>&1 | sed -E -n 's/.* version "([0-9]*).*$/\1/p')
    if [[ "$JAVA_MAJOR_VERSION" -ge "9" ]] ; then
        JVM_GC_LOG_OPTS="-Xlog:gc*:file=$JVM_GC_LOG:time,tags:filecount=10,filesize=102400"
    else
        JVM_GC_LOG_OPTS="-Xloggc:$JVM_GC_LOG -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=100M"
    fi

    JVM_OPTS="$JVM_GC_LOG_OPTS $JVM_OPTS"
fi

# Launch mode
exec $JAVA $JVM_HEAP_OPTS $JVM_PERF_OPTS $JMX_OPTS -cp $CLASSPATH $JVM_OPTS "$@"
