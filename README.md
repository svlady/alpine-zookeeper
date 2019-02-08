# alpine-zookeeper
Alpine-based minimal image containing OpenJDK8-JRE and Apache Zookeeper.

## Usage

```console
$ docker run -it --rm --net=host svlady/alpine-zookeeper:3.4.13
```


# Kubernetes Zookeeper
This project contains a Docker image meant to facilitate the deployment of 
[Apache ZooKeeper](https://zookeeper.apache.org/) on [Kubernetes](http://kubernetes.io/) using 
[StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/). 

## Limitations
1. Scaling up and down the ensemble is not supported in this Zookeeper version. 
Operators may resort to "rolling restarts" - a manual and error-prone method of 
changing the configuration that could cause data loss and inconsistency in 
production.
2. The [Observer](https://zookeeper.apache.org/doc/current/zookeeperObservers.html) 
feature is currently not supported by this project.

## Docker Image
The docker image that may be built out of this repository is based on Alpine linux
and includes the latest release of the OpenJDK JRE based on the 1.8 JVM (JDK 8u192)
as well as the latest stable release of ZooKeeper.

The image is providing a custom entrypoint which is dropping privileges and launches 
Zookeeper process as a non-root user (zookeeper). The Zookeeper package is installed 
into the `/opt/zookeeper` directory by default. This installation path can be 
specified as an argument during the package build.

## Container Configuration
The `bootstrap.sh` script will generate the ZooKeeper configuration (zoo.cfg), 
Log4J configuration (log4j.properties), and JVM configuration (jvm.env). These 
will be written to the `/opt/zookeeper/conf` directory with correct read 
permissions for the zookeeper user. These files are generated from environment 
variables that are injected into the container.

### Membership Configuration
|Variable|Type|Default|Description|
|:------:|:---:|:-----:|:---------|
|ZK_SERVERS|string|N/A|A colon separated list of servers in the ensemble.|

This is a mandatory configuration variable that is used to configure the membership 
of the Zookeeper ensemble. It is also used to prevent data loss during accidental 
scale operations. For example:

```
ZK_SERVERS=zk-0.zookeeper-headless:2888:3888;zk-1.zookeeper-headless:2888:3888;zk-2.zookeeper-headless:2888:3888
```

### Network Configuration
|Variable|Type|Default|Description|
|:------:|:---:|:-----:|:--------|
|ZK_CLIENT_PORT|integer|2181|The port on which the server will accept client requests.|
|ZK_SERVER_PORT|integer|2888|The port on which the leader will send events to followers.|
|ZK_ELECTION_PORT|integer|3888|The port on which the ensemble performs leader election.|
|ZK_MAX_CLIENT_CNXNS|integer|60|The maximum number of concurrent client connections that a server in the ensemble will accept.|

The ZK_CLIENT_PORT, ZK_ELECTION_PORT, and ZK_SERVERS_PORT must be set to the containerPorts 
specified in the container configuration, and the ZK_SERVER_PORT and ZK_ELECTION_PORT 
must match the Headless Service configuration. However, if the default values of 
the environment variables are used for both the containerPorts and the Headless Service, the 
environment variables may be omitted from the configuration.

### Zookeeper Time Configuration
|Variable|Type|Default|Description|
|:------:|:---:|:-----:|:--------|
|ZK_TICK_TIME|integer|2000|The number of wall clock ms that corresponds to a Tick for the ensembles internal time.|
|ZK_INIT_LIMIT|integer|5|The number of Ticks that an ensemble member is allowed to perform leader election.|
|ZK_SYNC_LIMIT|integer|10|The number of Tick by which a follower may lag behind the ensembles leader.|

These environment variables may be omitted and the values specified above will be used by default.

### Zookeeper Session Configuration
|Variable|Type|Default|Description|
|:------:|:---:|:-----:|:--------|
|ZK_MIN_SESSION_TIMEOUT|integer|2 * ZK_TICK_TIME|The minimum session timeout that the ensemble will allow a client to request.|
|ZK_MAX_SESSION_TIMEOUT|integer|20 * ZK_TICK_TIME|The maximum session timeout that the ensemble will allow a client to request.|

These environment variables may be omitted and the values specified above will be used by default.

### Data Retention Configuration
If you do not have an existing retention policy and backup procedure, and if you are comfortable with 
an automatic procedure, you can use the environment variables below to enable and configure 
automatic data purge policies.

|Variable|Type|Default|Description|
|:------:|:---:|:-----:|:---------|
|ZK_SNAP_RETAIN_COUNT|integer|3|The number of snapshots that the ZooKeeper process will retain if ZK_PURGE_INTERVAL is set to a value greater than 0.|
|ZK_PURGE_INTERVAL|integer|0|The delay, in hours, between ZooKeeper log and snapshot cleanups.|

These environment variables may be omitted and the values specified above will be used by default.

Please note: **Zookeeper does not, by default, purge old transactions logs or 
snapshots. This can cause the disk to become full.** If you have backup procedures 
and retention policies that rely on external systems, the snapshots and data logs
can be retrieved manually from the `/opt/zookeeper/data` and `/opt/zookeeper/logs`
directories correspondingly. These will be stored on the persistent volume. The 
`zkCleanup.sh` script can be used to manually purge outdated logs and snapshots.

### JVM Configuration
Currently the only supported JVM configuration is the JVM heap size. Be sure that 
the heap size you request does not cause the process to swap out or being killed 
due to OOM Exception, when reaching the limit alotted to container or pod.

|Variable|Type|Default|Description|
|:------:|:---:|:-----:|:--------|
|ZK_HEAP_SIZE|integer|2|The JVM heap size.|

### Log Level Configuration
The ZooKeeper process must be run in the foreground, and the log information will 
be shipped to the stdout or stderr. This is considered to be a best practice for 
containerized applications. The following variable `ZK_LOG_LEVEL` is providing a 
threshold  for the log messages sent to the console.

Shall you need to fine-tune logging facilities for specific log producers, you
may use `ZK_LOG4J_LOGGERS` variable to specify different log levels and 
thresholds as defined by LOG4J specification. For example you may use the 
following configuration to drop log messages caused by each client connection
due to pod liveness and readiness checks.

```
ZK_LOG4J_LOGGERS=org.apache.zookeeper.server.NIOServerCnxnFactory=WARN,org.apache.zookeeper.server.NIOServerCnxn=WARN
```

|Variable|Type|Default|Description|
|:------:|:---:|:-----:|:--------|
|ZK_LOG_LEVEL|enum(TRACE,DEBUG,INFO,WARN,ERROR,FATAL)|INFO|The Log Level for the Zookeeper processes logger.|
|ZK_LOG4J_LOGGERS|comma separated string|N/A|The Log Level for specific logger.|

### Liveness and Readiness Probes
The good way to check Zookeeper readiness is to use one of so called 
[4wl commands](https://zookeeper.apache.org/doc/r3.4.12/zookeeperAdmin.html#sc_zkCommands).
Healthy Zookeper shall answer `imok` to the `ruok` request sent to the 
client port. The example below demonstrates how to configure liveness 
and readiness probes for the Pods in the Stateful Set.

```yaml
  livenessProbe:
    exec:
      command: ['/bin/sh', '-c', 'echo "ruok" | nc -w 2 localhost 2181 | grep imok']
    initialDelaySeconds: 10
    timeoutSeconds: 5
  readinessProbe:
    exec:
      command: ['/bin/sh', '-c', 'echo "ruok" | nc -w 2 localhost 2181 | grep imok']
    initialDelaySeconds: 10
    timeoutSeconds: 5
```

There is a little caveat, though. By default, Zookepeer is accepting all
commands and for number of reasons you may want to allow only specific 
commands to be accepted. You can use the following setting to whitelist
only desired commands and ignore the rest.

```
ZK_CMD_WHITELIST="stat, ruok"
```

|Variable|Type|Default|Description|
|:------:|:---:|:-----:|:--------|
|ZK_CMD_WHITELIST|comma separated string|*|Allowed 4wl commands.|

### Volume Mounts
volumeMounts for the container should be defined as below.

```yaml
  volumeMounts:
  - name: datadir
    mountPath: /opt/zookeeper/data
```

## Storage Configuration
For production ready user-cases, the use of Persistent Volumes is mandatory.
Please note: **If you use the image with emptyDirs, you will likely suffer a data loss.** 

The example below demonstrates how to request a dynamically provisioned 
persistent volume of 20 GiB.

```yaml
  volumeClaimTemplates:
  - metadata:
      name: datadir
      annotations:
        volume.alpha.kubernetes.io/storage-class: anything
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 20Gi
```

