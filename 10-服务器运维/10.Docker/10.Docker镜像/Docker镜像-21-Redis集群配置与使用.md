# 基于 Docker 的 Redis 集群配置与使用

使用的镜像基本信息：colovu/redis:latest



## 基本约定

### 端口

- 6379：Redis 业务客户端访问端口
- 6380：Redis 业务客户端访问端口（TLS）
- 26379：Redis Sentinel 端口

### 数据卷

镜像默认提供以下数据卷定义，默认数据分别存储在自动生成的应用名对应`redis`子目录中：

```shell
/srv/data			# Redis 数据文件，主要存放Redis持久化数据；自动创建子目录redis
/srv/conf			# Redis 配置文件；自动创建子目录redis
/var/log			# 日志文件，日志文件名为：redis.log
/var/run			# 进程运行PID文件，PID文件名为：redis.pid、redis_sentinel.pid
```



## 基础准备



### 宿主机存储

如果需要做数据持久化存储，先创建相应的目录供后续相关命令使用。

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

伪集群，指的是在一个机器上设置多个服务容器作为集群提供服务，并不能提供冗余特性，主要用作开发及验证使用；如果主机因各种原因导致宕机，则所有 Redis 服务都会下线。如果需要完全的冗余特性，需要在完全独立的不同物理主机中启动服务容器；即使在一个集群的中的不同虚拟主机中启动单独的服务容器也无法完全避免因物理主机宕机导致的问题。

使用配置文件`docker-compose-cluster.yml`:

```yaml
version: '3.6'

services:
  redis-primary:
    image: 'colovu/redis:latest'
    ports:
      - '6379:6379'
    environment:
      - REDIS_REPLICATION_MODE=master
      - REDIS_PASSWORD=colovu
      - REDIS_DISABLE_COMMANDS=FLUSHDB,FLUSHALL

  redis-replica:
    image: 'colovu/redis:latest'
    ports:
      - '6379'
    environment:
      - REDIS_REPLICATION_MODE=slave
      - REDIS_MASTER_HOST=redis-primary
      - REDIS_MASTER_PORT_NUMBER=6379
      - REDIS_MASTER_PASSWORD=colovu
      - REDIS_PASSWORD=colovu
      - REDIS_DISABLE_COMMANDS=FLUSHDB,FLUSHALL
    depends_on:
      - redis-primary
```

> - 由于配置的是伪集群模式, 所以各个提供相同功能的 services 端口参数必须不同（使用同一个宿主机的不同端口）
> - '6379:6379'：指定宿主机端口与容器端口映射关系
> - '6379'：仅指定暴露容器端口，宿主机端口使用随机端口



### 下载镜像

可以不单独下载镜像，如果镜像不存在，会在初始化容器时自动下载：

```shell
$ docker-compose -f docker-compose-cluster.yml pull
```



### 启动集群

```shell
$ docker-compose -f docker-compose-cluster.yml up -d
```

以上方式将以 [replicated mode](https://redis.io/topics/cluster-tutorial) 启动 Redis 。也可以以  [Docker Swarm](https://www.docker.com/products/docker-swarm) 方式进行配置。



### 查看容器状态

可以使用 Docker 命令 或 Docker-Compose 命令查看当前运行的容器信息：

```shell
# 显示系统中所有运行的容器
$ docker ps

# 显示当前文件定义的服务对应的容器
$ docker-compose -f docker-compose-cluster.yml ps
```

![docker-cluster-ps](img/redis-cluster-ps.png)

查看指定容器的日志（容器shell脚本输出）：

```shell
# 使用容器服务名（如之前使用`docker ps`查询出的容器名）
$ docker-compose -f docker-compose-cluster.yml logs redis-replica

# 使用容器 ID 或 容器名（如之前`docker ps`查询出的容器 ID）
$ docker logs 70b5383df08d
$ docker logs docker-redis_redis-replica_1
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

![docker-cluster-scale](img/redis-cluster-scale-up.png)

**缩容后容器状态**

将集群中`redis-replica`服务缩容为两个服务容器：

![docker-cluster-scale-down](img/redis-cluster-scale-down.png)

### 验证容器可用性

链接至主服务节点`redis-primary`对应的容器`docker-redis_redis-primary_1`：

```shell
# 使用启动时定义的容器名或容器 ID
$ docker exec -it docker-redis_redis-primary_1 /bin/bash
$ docker exec -it 46a36df57207 /bin/bash
```



在容器中运行`entrypoint.sh`脚本，设置环境变量：

![docker-cluster-env](img/redis-cluster-env.png)

- 集群中配置了密码访问，可以使用`. /usr/local/bin/entrypoing.sh`方式设置`REDISCLI_AUTH`环境变量，规避在使用客户端是显示输入密码带来的风险
- 如果不运行该脚本，则运行`redis-cli`需要使用`-p xxxx`方式指定密码



在容器中使用`redis-cli`启动客户端，使用`ping`命令或`set`命令进行数据操作，验证服务可用性：

![docker-cluster-ping](img/redis-cluster-ping.png)

退出链接的容器：

![docker-cli-exit](img/redis-cluster-cli-exit.png)



链接至从服务节点`redis-replica`对应的其中一个容器`docker-redis_redis-replica_1`，查看之前设置的数据是否已经自动同步：

![docker-cluster-slave-get](img/redis-cluster-slave-get.png)



**从服务节点无法设置数据**

尝试在从服务节点设置数据，因设置的为主从复制模式，从节点不允许设置数据，会返回错误：

![docker-cluster-slave-set](img/redis-cluster-slave-set-6176412.png)



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

- 容器中 Redis 启动参数不能配置为后台运行，只能使用前台运行方式，即：`daemonize no`
- 如果应用使用后台方式运行，则容器的启动命令会在运行后自动退出，从而导致容器退出



## 附录

### 常规配置参数

常使用的环境变量主要包括：

- **ALLOW_EMPTY_PASSWORD**：默认值：**no**。设置是否允许无密码连接。如果没有设置`REDIS_PASSWORD`，则必须设置当前环境变量为 `yes`
- **REDIS_PASSWORD**：默认值：**无**。客户端认证的密码
- **REDIS_DISABLE_COMMANDS**：默认值：**无**。设置禁用的 Redis 命令
- **REDIS_AOF_ENABLED**：默认值：**yes**。设置是否启用 Append Only File 存储

### 可选配置参数

如果没有必要，可选配置参数可以不用定义，直接使用对应的默认值，主要包括：

- **ENV_DEBUG**：默认值：**false**。设置是否输出容器调试信息。可设置为：1、true、yes
- **REDIS_PORT**：默认值：**6379**。设置应用的默认客户访问端口
- **REDIS_PASSWORD_FILE**：默认值：**无**。以绝对地址指定的客户端认证用户密码存储文件。该路径指的是容器内的路径
- **REDIS_MASTER_PASSWORD_FILE**：默认值：**无**。以绝对地址指定的服务器密码存储文件。该路径指的是容器内的路径

### Sentinel配置参数

- **REDIS_SENTINEL_HOST**：默认值：**无**
- **REDIS_SENTINEL_MASTER_NAME**：默认值：**无**
- **REDIS_SENTINEL_PORT_NUMBER**：默认值：**26379**。设置 Sentinel 默认端口

### 集群配置参数

使用 Redis 镜像，可以很容易的建立一个 [redis](https://redis.apache.org/doc/r3.1.2/redisAdmin.html) 集群。针对 redis 的集群模式（复制模式），有以下参数可以配置：

- **REDIS_REPLICATION_MOD**：默认值：**无**。当前主机在集群中的工作模式，可使用值为：`master`/`slave`/`replica`
- **REDIS_MASTER_HOST**：默认值：**无**。作为`slave`/`replica`时，对应的 master 主机名或 IP 地址
- **REDIS_MASTER_PORT_NUMBER**：默认值：**6379**。master 主机对应的端口
- **REDIS_MASTER_PASSWORD**：默认值：**无**。master 主机对应的登录验证密码

### TLS配置参数

使用证书加密传输时，相关配置参数如下：

- **REDIS_TLS_ENABLED**：启用或禁用 TLS。默认值：**no**
 - **REDIS_TLS_PORT**：使用 TLS 加密传输的端口。默认值：**6379**
 - **REDIS_TLS_CERT_FILE**：TLS 证书文件。默认值：**无**
 - **REDIS_TLS_KEY_FILE**：TLS 私钥文件。默认值：**无**
 - **REDIS_TLS_CA_FILE**：TLS 根证书文件。默认值：**无**
 - **REDIS_TLS_DH_PARAMS_FILE**：包含 DH 参数的配置文件 (DH 加密方式时需要)。默认值：**无**
 - **REDIS_TLS_AUTH_CLIENTS**：配置客户端是否需要 TLS 认证。 默认值：**yes**

当使用 TLS 时，则默认的 non-TLS 通讯被禁用。如果需要同时支持 TLS 与 non-TLS 通讯，可以使用参数`REDIS_TLS_PORT`配置容器使用不同的 TLS 端口。



----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))

