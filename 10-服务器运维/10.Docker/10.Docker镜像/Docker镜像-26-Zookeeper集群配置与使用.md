# 基于 Docker 的 Zookeeper 集群配置与使用

使用的镜像基本信息：colovu/zookeeper:latest

在实际使用过程中，如果需要使用其他版本的镜像，请按照需要替换相关下载镜像的命令中对应的镜像 TAG。



## 基本约定

### 端口

- 2181：Zookeeper 业务客户端访问端口
- 2888：Follower port （跟随者通讯端口）
- 3888：Election port （选举通讯端口）
- 8080：AdminServer port （管理界面端口）

### 数据卷

镜像默认提供以下数据卷定义，默认数据分别存储在自动生成的应用名对应`zookeeper`子目录中：

```shell
/var/log			# 日志输出，应用日志输出，非数据日志输出；自动创建子目录zookeeper
/srv/conf			# 配置文件；自动创建子目录zookeeper
/srv/data			# 数据文件；自动创建子目录zookeeper
/srv/datalog	# 数据操作日志文件；自动创建子目录zookeeper
```



## 基础准备



### 宿主机存储

如果需要做数据持久化存储，先创建相应的目录供后续相关命令使用，如使用宿主机的`/tmp`目录存储数据。

```shell
 # 在宿主机创建相应数据存储目录
 $ mkdir /tmp/data /tmp/conf
```

- 上述路径在容器使用后，会自动创建对应的子目录以存储数据
- 容器初始化后，会生成相应的标识文件，不能删除；如果标识文件被修改，可能会导致数据丢失



### 容器网络

在工作在同一个网络组中时，如果容器需要互相访问，相关联的容器可以使用容器初始化时定义的名称作为主机名进行互相访问。

创建网络：

```shell
$ docker network create back-tier --driver bridge
```

- 使用桥接方式，创建一个命名为`back-tier`的网络

如果需要使用已创建的网络连接不同容器：

- 使用 Docker 命令行方式时，需要在启动命令中增加类似`--network back-tier`的参数
- 使用 Docker-Compose 时，需要在`docker-compose`配置文件中增加`external`描述：

```yaml
services:
	redis:
		...
		networks:
    	- back-tier
  ...
networks:
  back-tier:
    external: back-tier
```



## 伪集群

伪集群，指的是在一个机器上设置多个服务容器作为集群提供服务，并不能提供冗余特性，主要用作开发及验证使用；如果主机因各种原因导致宕机，则所有 Zookeeper 服务都会下线。如果需要完全的冗余特性，需要在完全独立的不同物理主机中启动服务容器；即使在一个集群的中的不同虚拟主机中启动单独的服务容器也无法完全避免因物理主机宕机导致的问题。

建议使用奇数个主机组成集群。如果集群中有5台服务器，则可以支持2台机器的宕机。

针对集群中，当前主机的配置信息，其IP地址必须使用`0.0.0.0`；在配置信息中，其表现为主机ID与server信息中编号一致。如针对ID为1的配置信息，可类似如下：`0.0.0.0:2888:3888 zookeeper2:2888:3888 zookeeper3:2888:3888`。

可以使用 [`docker stack deploy`](https://docs.docker.com/engine/reference/commandline/stack_deploy/) 或 [`docker-compose`](https://github.com/docker/compose) 方式，启动一组服务容器。使用配置文件`docker-compose-zk-vcluster.yml`参考如下:

```yaml
version: '3.6'

services:
  zoo1:
    image: colovu/zookeeper:latest
    restart: always
    ports:
      - 2181:2181
    environment:
      - ZOO_SERVER_ID=1
      - ALLOW_ANONYMOUS_LOGIN=yes
      - ZOO_SERVERS="server.1=0.0.0.0:2888:3888 server.2=zoo2:2888:3888 server.3=zoo3:2888:3888"

  zoo2:
    image: colovu/zookeeper:latest
    restart: always
    ports:
      - 2182:2181
    environment:
      - ZOO_SERVER_ID=2
      - ALLOW_ANONYMOUS_LOGIN=yes
      - ZOO_SERVERS="server.1=zoo1:2888:3888 server.2=0.0.0.0:2888:3888 server.3=zoo3:2888:3888"

  zoo3:
    image: colovu/zookeeper:latest
    restart: always
    ports:
      - 2183:2181
    environment:
      - ZOO_SERVER_ID=3
      - ALLOW_ANONYMOUS_LOGIN=yes
      - ZOO_SERVERS="server.1=zoo1:2888:3888 server.2=zoo2:2888:3888 server.3=0.0.0.0:2888:3888"
```

> - 由于配置的是伪集群模式, 所以各个提供相同功能的 services 端口参数必须不同（使用同一个宿主机的不同端口）



### 下载镜像

可以不单独下载镜像，如果镜像不存在，会在初始化容器时自动下载：

```shell
$ docker-compose -f docker-compose-zk-vcluster.yml pull
```



### 启动集群

```shell
$ docker-compose -f docker-compose-zk-vcluster.yml up -d
```

以上方式将以 [replicated mode](https://redis.io/topics/cluster-tutorial) 启动 Redis 。也可以以  [Docker Swarm](https://www.docker.com/products/docker-swarm) 方式进行配置。



### 查看容器状态

可以使用 Docker 命令 或 Docker-Compose 命令查看当前运行的容器信息：

```shell
# 显示系统中所有运行的容器
$ docker ps

# 显示当前文件定义的服务对应的容器
$ docker-compose -f docker-compose-zk-vcluster.yml ps
```

![zookeeper-vcluster-ps](img/zookeeper-vcluster-ps.png)

查看指定容器的日志（容器shell脚本输出）：

```shell
# 使用容器服务名（如之前使用`docker ps`查询出的容器名）
$ docker-compose -f docker-compose-zk-vcluster.yml logs zoo1

# 使用容器 ID 或 容器名（如之前`docker ps`查询出的容器 ID）
$ docker logs e1e406d3c39b
$ docker logs tmp_zoo1_1
```

- 生成的容器命名规则：当前目录-服务名-序号
- 如果定义服务的时候，使用了`container-name:`属性，则无法动态扩容。但容器名为 YAML 中配置的容器名



### 动态扩容与缩容

```shell
$ docker-compose -f docker-compose-cluster.yml scale redis-replica=3
```

以上命令，将 replicated 容器增加为 3 台，也可以使用类似命令减少容器数量。

> 不能增加/减少 primary 容器的数量，仅能存在一个 primary 容器节点。

**扩容后容器状态**

将集群中`redis-replica`服务扩容为三个服务容器：

![docker-cluster-scale](img/docker-cluster-scale-up.png)

**缩容后容器状态**

将集群中`redis-replica`服务缩容为两个服务容器：

![docker-cluster-scale-down](img/docker-cluster-scale-down.png)

### 验证容器可用性

链接至其中一个 Zookeeper 容器节点，并使用命令`zkServer.sh status`查看服务状态，至少有一个为`leader`，其余的为`follower`:

```shell
# 使用启动时定义的容器名或容器 ID
$ docker exec -it tmp_zoo1_1 /bin/bash
$ docker exec -it e1e406d3c39b /bin/bash
```



在容器中运行`entrypoint.sh`脚本，设置环境变量：

![zookeeper-vcluster-env](img/zookeeper-vcluster-env.png)

在容器中使用`zkServer.sh status`命令查询容器状态，至少有一个为`leader`，其余的为`follower`：

![zookeeper-vcluster-status](img/zookeeper-vcluster-status.png)

![zookeeper-vcluster-status-leader](img/zookeeper-vcluster-status-leader.png)

在容器中使用`zkCli.sh -server zoo1:2181  get /`命令查询数据信息，可在集群中任意一个容器中或客户端上查询任意一个容器内的数据信息，如在`zoo1`容器中使用`zkCli.sh -server zoo3:2181 get /`命令查询`zoo3`容器中数据信息：

![zookeeper-vcluster-get](img/zookeeper-vcluster-get.png)

退出容器：

![zookeeper-vcluster-exit](img/zookeeper-vcluster-exit.png)

### 其他容器操作

以下命令中的配置文件，默认为`docker-compose.yml`；容器指定，可以使用容器 ID（如 0a8d4ab79f92 ） 或容器名（如 0a8d4ab79f92 ）：

```shell
# 停止所有服务，并删除容器
$ docker-compose down

# 重新创建并启动所有服务容器（或指定服务）
$ docker-compose up -d --force-recreate 
$ docker-compose up -d --force-recreate redis-replica

# 停止指定服务对应的容器
$ docker-compose stop redis-replica

# 启动指定服务对应的容器
$ docker-compose start redis-replica

# 删除已停止的服务对应的容器
$ docker-compose rm redis-replica

# 重启服务对应的容器（含扩容后的容器）
$ docker-compose restart redis-replica
```

> 注意：
>
> - `--force-recreate` 命令执行时，并不会自动重新根据之前的扩容指令创建新的容器；如果`recreate`之前从一个容器扩容为了三个容器，则`recreate`之后，只会有一个容器运行



## 容器配置

在初始化 redis 容器时，如果应用默认配置文件不存在，可以在初始化容器时使用相应参数对默认参数进行修改。

在配置文件中，增加`environment:`定义，YAML 文件中存在类似如下内容：

```yaml
services:
  redis:
    ...
    environment:
    	- REDIS_PASSWORD=colovu
    ...
```



### SSL配置参数

当使用 TLS 时，则默认的 non-TLS 通讯被禁用。如果需要同时支持 TLS 与 non-TLS 通讯，可以使用参数`REDIS_TLS_PORT`配置容器使用不同的 TLS 端口。

如：本地`/tmp/cert`目录中包含`redis`子目录，并存在相应的证书文件。

YAML 文件中存在类似如下内容：

```yaml
services:
  redis:
  ...
    environment:
      ...
      - REDIS_TLS_ENABLED=yes
      - REDIS_TLS_PORT=6380
      - REDIS_TLS_CERT_FILE=/srv/cert/redis/redis.crt
      - REDIS_TLS_KEY_FILE=/srv/cert/redis/redis.key
      - REDIS_TLS_CA_FILE=/srv/cert/redis/redisCA.crt
    volumes:
      - /tmp/cert:/srv/cert
  ...
```

> 注意：
>
> - /tmp/cert 中需要包含 redis 子目录，且相应证书文件存放在该位置；文件权限需要为`400`
> - `/srv/cert/redis/...` 指的是容器内的路径，不可以修改





## 注意事项

### 容器中应用运行方式

- 容器中启动参数不能配置为后台运行，如果应用使用后台方式运行，则容器的启动命令会在运行后自动退出，从而导致容器退出；只能使用前台运行方式，即：`start-foreground`



## 附录

### 常规配置参数

常使用的环境变量主要包括：

- **ALLOW_ANONYMOUS_LOGIN**：默认值：**no**。设置是否允许匿名连接。如果没有设置`ZOO_ENABLE_AUTH`，则必须设置当前环境变量为 `yes`
- **ZOO_LISTEN_ALLIPS_ENABLED**：默认值：**no**。设置是否默认监听所有 IP
- **ZOO_TICK_TIME**：默认值：**2000**。设置`tickTime`。定义一个 Tick 的时间长度，以微秒为单位。该值为 ZooKeeper 使用的基础单位，用于心跳、超时等控制；如一般 Session 的最小超时时间为2个 Ticks
- **ZOO_INIT_LIMIT**：默认值：**10**。设置 `initLimit`。以 ticks 为单位的时间长度。用于控制从服务器与 Leader 连接及同步的时间。如果数据量比较大，可以适当增大该值
- **ZOO_SYNC_LIMIT**：默认值：**5**。设置`syncLimit`。以 ticks 为单位的时间长度。用于控制从服务器同步数据的时间。如果从服务器与 Leader 差距过大，将会被剔除
- **ZOO_MAX_CLIENT_CNXNS**：默认值：**60**。设置`maxClientCnxns`。每个客户端允许的同时连接数（Socket层）。以 IP 地址来识别客户端
- **ZOO_STANDALONE_ENABLED**：默认值：**false**。设置使用启用 Standalone 模式。参考[`standaloneEnabled`](https://zookeeper.apache.org/doc/r3.5.5/zookeeperReconfig.html#sc_reconfig_standaloneEnabled)中的定义。

> 3.5.0版本新增。配置服务器工作模式，支持 Standalone 和 Distributed 两种。在服务器启动后无法重新切换。服务器启动时，默认会设置为 true，服务器将无法动态扩展。为了后续服务器可动态扩展，可设置该值为 false。

- **ZOO_ADMINSERVER_ENABLED**：默认值：**true**。 设置是否启用管理服务器。参考[`admin.enableServer`](http://zookeeper.apache.org/doc/r3.5.5/zookeeperAdmin.html#sc_adminserver_config)中定义。

> 3.5.0版本新增。 配置是否启用 AdminServer，该服务是一个内置的 Jetty 服务器，可以提供 HTTP 访问端口以支持四字命令。默认情况下，该服务工作在 8080 端口，访问方式为： URL "/commands/[command name]", 例如, http://localhost:8080/commands/stat。

- **ZOO_AUTOPURGE_PURGEINTERVAL**：默认值：**0**。设置自动清理触发周期，参考 [`autoPurge.purgeInterval`](https://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_advancedConfiguration)中的定义。以小时为单位自动清理触发时间。设置为正整数（1 或更大值）以启用服务器自动清理快照及日志功能。设置为 0 则不启用。
- **ZOO_AUTOPURGE_SNAPRETAINCOUNT**：默认值：**3**。设置自动清理范围，参考[`autoPurge.snapRetainCount`](https://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_advancedConfiguration)中的定义。当自动清理功能启用时，保留的最新快照或日志数量；其他的快照及保存在 dataDir、dataLogDir 中的数据将被清除。最小值为 3。

- **ZOO_4LW_COMMANDS_WHITELIST**：默认值：**srvr, mntr**。设置白名单，参考 [`4lw.commands.whitelist`](https://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_clusterOptions)中的定义。以逗号分隔的四字命令。需要将有效的四字命令使用该环境变量进行设置；如果不设置，则对应的四字命令默认不起作用。



### 可选配置参数

如果没有必要，可选配置参数可以不用定义，直接使用对应的默认值，主要包括：

- **ENV_DEBUG**：默认值：**false**。设置是否输出容器调试信息。可设置为：1、true、yes
- **ZOO_PORT_NUMBER**：默认值：**2181**。设置应用的默认客户访问端口
- **ZOO_MAX_CNXNS**：默认值：**0**。设置当前服务器最大连接数。设置为 0 则无限制
- **ZOO_LOG4J_PROP**：默认值：**INFO,CONSOLE**。设置日志输出级别及输出方式；开启多种输出方式时，会影响应用程序性能。日志级别取值范围：`ALL`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`, `OFF`, `TRACE`。输出方式取值可为多个，以`,`分隔，取值范围：`CONSOLE`、`ROLLINGFILE`、`TRACEFILE`
- **ZOO_RECONFIG_ENABLED**：默认值：**no**。设置是否启用动态重新配置功能
- **ZOO_ENABLE_PROMETHEUS_METRICS**：默认值：**no**。设置是否输出 Prometheus 指标
- **ZOO_PROMETHEUS_METRICS_PORT_NUMBER**：默认值：**7000**。设置 Jetty 默认输出 Prometheus 指标的端口
- **ZOO_ENABLE_AUTH**：默认值：**no**。设置是否启用认证。使用  SASL/Digest-MD5 加密
- **ZOO_CLIENT_USER**：默认值：**无**。客户端认证的用户名
- **ZOO_CLIENT_PASSWORD**：默认值：**无**。客户端认证的用户密码
- **ZOO_CLIENT_PASSWORD_FILE**：默认值：**无**。以绝对地址指定的客户端认证用户密码存储文件。该路径指的是容器内的路径
- **ZOO_SERVER_USERS**：默认值：**无**。服务端创建的用户列表。多个用户使用逗号、分号、空格分隔
- **ZOO_SERVER_PASSWORDS**：默认值：**无**。服务端创建的用户对应的密码。多个用户密码使用逗号、分号、空格分隔。例如：pass4user1, pass4user2, pass4admin
- **ZOO_SERVER_PASSWORDS_FILE**：默认值：**无**。以绝对地址指定的服务器用户密码存储文件。多个用户密码使用逗号、分号、空格分隔。例如：pass4user1, pass4user2, pass4admin。该路径指的是容器内的路径
- **JVMFLAGS**：默认值：**无**。设置服务默认的 JVMFLAGS
- **HEAP_SIZE**：默认值：**1024**。设置以 MB 为单位的 Java Heap 参数（Xmx 与 Xms）。如果在 JVMFLAGS 中已经设置了 Xmx 与 Xms，则当前设置会被忽略



### 集群配置参数

使用 ZooKeeper 镜像，可以很容易的建立一个 [ZooKeeper](https://zookeeper.apache.org/doc/r3.1.2/zookeeperAdmin.html) 集群。针对 ZooKeeper 的集群模式，有以下参数可以配置：

#### `ZOO_SERVER_ID`

默认值：**1**

介于1~255之间的唯一值，用于标识服务器ID。需要注意，如果在初始化容器时使用一个存在`myid`文件的宿主机路径映射为容器的`/srv/data`数据卷，则相应的`ZOO_SERVER_ID`参数设置不起作用。容器中文件完整路径为：`/srv/data/zookeeper/myid`。

#### `ZOO_SERVERS`

默认值：**server.1=0.0.0.0:2888:3888**

定义集群模式时的服务器列表。每个服务器使用类似`server.id=host:port:port`的格式进行定义，如：`server.2=192.168.0.1:2888:3888`。不同的服务器参数使用空格或逗号分隔。需要注意，如果在初始化容器时使用一个存在`zoo.cfg`文件的本地路径映射为`/srv/conf`数据卷，则相应的参数设置不起作用。文件完整路径为：`/srv/conf/zookeeper/zoo.conf`。此时如果需要更新配置，只能手动修改配置文件，并重新启动容器。

常用格式为 `server.X=A:B:C`，参考信息如下:

- `server.`: 关键字，不可以更改
- X: 数字，当前服务器的ID，在同一个集群中应当唯一
- A: IP地址或主机名（网络中可识别）
- B: 当前服务器与集群中 Leader 交换消息所使用的端口
- C: 选举 Leader 时所使用的端口

更多信息，可参照文档 [Zookeeper Dynamic Reconfiguration](https://zookeeper.apache.org/doc/r3.5.5/zookeeperReconfig.html) 中的介绍。



### TLS配置参数

使用证书加密传输时，相关配置参数如下：

- **ZOO_TLS_CLIENT_ENABLE**：启用或禁用 TLS。默认值：**no**
- **ZOO_TLS_PORT_NUMBER**：使用 TLS 加密传输的端口。默认值：**3181**
- **ZOO_TLS_CLIENT_KEYSTORE_FILE**：
- **ZOO_TLS_CLIENT_KEYSTORE_PASSWORD**：
- **ZOO_TLS_CLIENT_TRUSTSTORE_FILE**：
- **ZOO_TLS_CLIENT_TRUSTSTORE_PASSWORD**：

- **ZOO_TLS_QUORUM_ENABLE**：启用或禁用Quorum的 TLS。默认值：**no**
- **ZOO_TLS_QUORUM_KEYSTORE_FILE**：
- **ZOO_TLS_QUORUM_KEYSTORE_PASSWORD**：
- **ZOO_TLS_QUORUM_TRUSTSTORE_FILE**：
- **ZOO_TLS_QUORUM_TRUSTSTORE_PASSWORD**：



----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))

