FROM svlady/alpine-openjdk8-jre:8.191.12-r0
LABEL maintainer="slava.vladyshevsky[a]gmail.com"

ARG PKG_VERSION=3.4.13
ARG PKG_NAME=zookeeper-${PKG_VERSION}
ARG ZK_HOME=/opt/zookeeper
ARG ZK_CLIENT_PORT=2181

ENV PATH=$PATH:$ZK_HOME/bin \
    ZOO_LOG4J_PROP=INFO,CONSOLE \
    ZK_USER=zookeeper \
    ZK_HOME=${ZK_HOME}

RUN set -ex && \
    apk add --no-cache bash su-exec && \
    adduser -D -u 1000 -H -h ${ZK_HOME} ${ZK_USER} && \
    addgroup ${ZK_USER} root && \
    cd /tmp && \
    wget -q "https://www.apache.org/dist/zookeeper/${PKG_NAME}/${PKG_NAME}.tar.gz" && \
    wget -q "https://www.apache.org/dist/zookeeper/${PKG_NAME}/${PKG_NAME}.tar.gz.sha1" && \
    sha1sum -c ${PKG_NAME}.tar.gz.sha1 && \
    tar -zxf ${PKG_NAME}.tar.gz && \
    mkdir -m 0775 -p ${ZK_HOME}/bin ${ZK_HOME}/lib ${ZK_HOME}/conf ${ZK_HOME}/data ${ZK_HOME}/logs && \
    install -o 1000 -g 0 -m 775 "${PKG_NAME}/bin/"*.sh ${ZK_HOME}/bin && \
    install -o 1000 -g 0 -m 664 "${PKG_NAME}/"*.jar "${PKG_NAME}/lib/"*.jar ${ZK_HOME}/lib && \
    rm -rf ${PKG_NAME} ${PKG_NAME}.tar.gz ${PKG_NAME}.tar.gz.sha1

# adding entrypoint and startup scripts
COPY *.sh $ZK_HOME/bin/

WORKDIR ${ZK_HOME}
EXPOSE ${ZK_CLIENT_PORT} 2888 3888
VOLUME ["${ZK_HOME}/data", "${ZK_HOME}/logs"]

ENTRYPOINT ["entrypoint.sh"]
CMD ["bootstrap.sh", "zkServer.sh", "start-foreground"]
