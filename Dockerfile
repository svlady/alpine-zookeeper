FROM svlady/alpine-openjdk8-jre:8.191.12-r0

ARG DISTRO_NAME=zookeeper-3.5.4-beta
ARG ZK_PREFIX=/opt/zookeeper

# setting several env variables for compatibility with Zk provided tools and scripts
# these values aeree also used to automatically generate configuration if not found
ENV PATH=$PATH:$ZK_PREFIX/bin \
    ZOOCFG=zookeeper.properties \
    ZOOBINDIR=$ZK_PREFIX/bin \
    ZOOLIBDIR=$ZK_PREFIX/lib \
    ZOOCFGDIR=$ZK_PREFIX/conf \
    ZOODATADIR=$ZK_PREFIX/data \
    ZOOLOGSDIR=$ZK_PREFIX/logs \
    ZK_USER=zookeeper \
    ZK_PORT=2181 \
    ZK_TICK_TIME=2000 \
    ZK_INIT_LIMIT=5 \
    ZK_SYNC_LIMIT=2 \
    ZK_AUTOPURGE_PURGEINTERVAL=0 \
    ZK_AUTOPURGE_SNAPRETAINCOUNT=3 \
    ZK_MAX_CLIENT_CNXNS=60 \
    ZK_STANDALONE_ENABLED=false

RUN set -ex && \
    echo "===> Install required packages..." && \
    apk add --no-cache bash su-exec && \
    echo "===> Setup Zookeeper user..." && \
    addgroup -g 1000 "$ZK_USER" && \
    adduser -D -u 1000 -G "$ZK_USER" -H -h "$ZK_PREFIX" "$ZK_USER" && \
    addgroup "$ZK_USER" root && \
    echo "===> Install Zookeeper..." && \
    cd /tmp && \
    wget -q "https://www.apache.org/dist/zookeeper/$DISTRO_NAME/$DISTRO_NAME.tar.gz" && \
    wget -q "https://www.apache.org/dist/zookeeper/$DISTRO_NAME/$DISTRO_NAME.tar.gz.sha1" && \
    sha1sum -c $DISTRO_NAME.tar.gz.sha1 && \
    tar -zxf "$DISTRO_NAME.tar.gz" && \
    mkdir -p $ZOOBINDIR $ZOOLIBDIR $ZOOCFGDIR $ZOODATADIR $ZOOLOGSDIR && \
    chmod -R 0775 "$ZK_PREFIX" && \
    chown -R "$ZK_USER:root" "$ZK_PREFIX" && \
    install -o 1000 -g 0 -m 775 "$DISTRO_NAME/bin/"*.sh "$ZOOBINDIR" && \
    install -o 1000 -g 0 -m 660 "$DISTRO_NAME/conf/"*   "$ZOOCFGDIR" && \
    install -o 1000 -g 0 -m 664 "$DISTRO_NAME/"*.jar "$DISTRO_NAME/lib/"*.jar "$ZOOLIBDIR" && \
    echo "===> Cleaning up..." && \
    rm -rf "$DISTRO_NAME" "$DISTRO_NAME.tar.gz" "$DISTRO_NAME.tar.gz.sha1"

# adding entrypoint and startup scripts
COPY *.sh $ZOOBINDIR/

WORKDIR $ZK_PREFIX
EXPOSE $ZK_PORT 2888 3888
VOLUME ["$ZOOCFGDIR", "$ZOODATADIR", "$ZOOLOGSDIR"]

ENTRYPOINT ["entrypoint.sh"]
CMD ["zookeeper.sh"]
