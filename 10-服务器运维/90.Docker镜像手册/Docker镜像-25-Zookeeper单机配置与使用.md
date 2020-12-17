# 基于 Docker 的 Zookeeper 单机配置与使用



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

如果需要做数据持久化存储，先创建相应的目录供后续相关命令使用，如使用宿主机的`/tmp`目录存储数据：

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
	zookeeper:
		...
		networks:
    	- back-tier
  ...
networks:
  back-tier:
    external: back-tier
```



## 基于 Docker 命令行

### 下载镜像

可以不单独下载镜像，如果镜像不存在，会在初始化容器时自动下载。

```shell
# 下载指定Tag的镜像
$ docker pull colovu/zookeeper:tag

# 下载最新镜像
$ docker pull colovu/zookeeper:latest
```

> TAG：替换为需要使用的指定标签名

### 实例化服务容器

生成并运行一个新的容器：

```shell
$ docker run -d --name zookeeper -p 2181:2181 -e ALLOW_ANONYMOUS_LOGIN=yes colovu/zookeeper:latest
```

- `-d`: 使用服务方式启动容器
- `--name zookeeper`: 为当前容器命名
- `-e ALLOW_ANONYMOUS_LOGIN=yes`: 设置默认允许任意用户登录（调试时使用，生产系统应当使用密码认证）



如果需要数据持久化，可以使用数据卷映射生成并运行一个容器：

```shell
 
 $ docker run -d --name zookeeper -p 2181:2181 -e ALLOW_ANONYMOUS_LOGIN=yes \
  -v /tmp/data:/srv/data \
  -v /tmp/conf:/srv/conf \
  colovu/zookeeper:latest
```

- `/tmp/data`：存储 zookeeper 缓存数据
- `/tmp/conf`：存储容器配置文件

> 注意：将数据持久化存储至宿主机，可避免容器销毁导致的数据丢失。同时，将数据存储及数据日志分别映射为不同的本地设备（如不同的共享数据存储）可提供较好的性能保证。



### 查看容器状态

查看当前运行的所有容器：

```shell
$ docker ps
```

![zookeeper-single-ps](img/zookeeper-single-ps.png)

查看指定容器的日志（容器shell脚本输出的日志信息）：

```shell
# 使用启动时定义的容器名或容器 ID
$ docker logs zookeeper
$ docker logs 0b7b2706a2b2
```



### 验证容器可用性

链接容器：

```shell
# 使用启动时定义的容器名或容器 ID
$ docker exec -it zookeeper /bin/bash
$ docker exec -it 0a8d4ab79f92 /bin/bash
```



在容器中使用`zkCli.sh`启动客户端，并获取服务器注册信息：

```shell
$ zkCli.sh -server localhost:2181  get /
```



### 链接至容器并使用

启用 [Docker container networking](https://docs.docker.com/engine/userguide/networking/)后，基于同一网络的容器间互相通讯时，可以直接使用已定义的容器名进行链接后使用。

如之前的容器启动命令中包含网络设置：

```shell
$ docker run -d --name zookeeper --network back-tier -p 2181:2181 \
	-e ALLOW_ANONYMOUS_LOGIN=yes colovu/zookeeper:latest
```

- `back-tier`： 之前已创建的容器网络



```shell
$ docker run -d --name other-app --network back-tier \
	--link zookeeper:zookeeper.server other-app-image:tag
```

- `--link zookeeper:zookeeper.server`: 连接运行中的`zookeeper`容器，并命名为`zookeeper.server`供`app-name`内应用使用（如 容器中应用使用`zookeeper.server`进行寻址访问）



### 其他容器操作

以下命令中的容器指定，可以使用容器名（如 zookeeper ），也可以使用容器 ID （如 0a8d4ab79f92 ）：

```shell
# 停止容器
$ docker stop zookeeper

# 启动容器
$ docker start zookeeper

# 删除已停止的容器
$ docker rm zookeeper

# 重启容器
$ docker restart zookeeper
```



## 基于 Docker-Compose 命令

使用配置文件`docker-compose-test.yml`:

```yaml
version: '3.6'

services:
  zookeeper:
    image: 'colovu/zookeeper:latest'
    ports:
      - '2181:2181'
    environment:
      - ALLOW_ANONYMOUS_LOGIN=yes
      - ZOO_LISTEN_ALLIPS_ENABLED=yes
```



### 下载镜像

可以不单独下载镜像，如果镜像不存在，会在初始化容器时自动下载：

```shell
$ docker-compose -f docker-compose-test.yml pull
```



### 实例化服务容器

启动 YAML 中定义的服务（如果有依赖服务，会先启动依赖服务）：

```shell
# 启动所有服务
$ docker-compose -f docker-compose-test.yml up -d

# 启动指定服务
$ docker-compose -f docker-compose-test.yml up -d zookeeper
```

- 如果配置文件命名为`docker-compose.yml`，可以省略`-f docker-compose-test.yml`参数



如果需要数据持久化，可以使用已存在的宿主机目录映射为容器数据卷，生成并运行容器；YAML 文件包含类似如下内容：

```yaml
services:
  zookeeper:
    ...
    volumes: 
      - /tmp/data:/srv/data
      - /tmp/conf:/srv/conf
    ...
```

- 每个需要持久化保存数据的容器，都需要包含`volumes:`配置信息
- 路径建议使用绝对路径；但在 Linux 中可以使用`${PWD}`指定为当前路径



### 查看容器状态

可以使用 Docker 命令 或 Docker-Compose 命令查看当前运行的容器信息：

```shell
# 显示系统中所有运行的容器
$ docker ps

# 显示当前文件定义的服务对应的容器
$ docker-compose -f docker-compose-test.yml ps
```



查看指定容器的日志（容器shell脚本输出）：

```shell
# 使用已定义的容器名（如之前启动时使用`--name zookeeper`命名的容器）
$ docker-compose -f docker-compose-test.yml logs zookeeper

# 使用容器 ID（如之前`docker ps`查询出的容器 ID）
$ docker-compose -f docker-compose-test.yml logs e368763a2a63
```



### 验证容器可用性

验证操作可参考 `基于 Docker 命令行`中对应小结；除可以使用 Docker 命令对容器（容器名或容器 ID）进行操作外，也可以使用 Docker-Compose 命令对容器进行操作（以下命令默认配置文件名为`docker-compose.yml`）：

```shell
# exec 命令不需要指定交互模式的参数`-it`
$ docker-compose exec zookeeper zkCli.sh -server localhost:2181  get /
```



### 链接至容器并使用

在一个 YAML 文件中定义的各个服务之间，默认是基于同一个网络，可以直接使用服务名进行互相访问。

```yaml
version: '3.6'

services:
  zookeeper:
    image: 'colovu/zookeeper:latest'
    ports:
    	- 2181:2181
    environment:
    	- ALLOW_ANONYMOUS_LOGIN=yes
    	
  myapp:
    image: 'other-app-img:tag'
    links:
    	- zookeeper:zookeeper.server
```

- `zookeeper:zookeeper.server`： 如果其他容器中定义的访问主机名与服务名不一致，可以以`link`的方式定义新的名字（如，新的应用中以`zookeeper.server`主机名进行寻址访问）



### 其他容器操作

以下命令中的配置文件，默认为`docker-compose.yml`；容器指定，可以使用服务名（如 zookeeper ），也可以使用容器 ID 或容器名（如 0a8d4ab79f92 ）：

```shell
# 停止所有服务，并删除容器
$ docker-compose down

# 重新创建并启动所有服务容器（或指定服务）
$ docker-compose up -d --force-recreate 
$ docker-compose up -d --force-recreate zookeeper

# 停止指定服务容器
$ docker-compose stop zookeeper

# 启动指定服务容器
$ docker-compose start zookeeper

# 删除已停止的容器
$ docker-compose rm zookeeper

# 重启服务容器
$ docker-compose restart zookeeper
```



## 容器配置

在初始化 zookeeper 容器时，如果应用默认配置文件不存在，可以在初始化容器时使用相应参数对默认参数进行修改。

Docker 命令行方式时类似命令如下：

```shell
$ docker run -d --restart always -e ALLOW_ANONYMOUS_LOGIN=yes -e "ZOO_INIT_LIMIT=10" --name zookeeper colovu/zookeeper:latest
```

Docker-Compose 方式时，增加`environment:`定义，YAML 文件中存在类似如下内容：

```yaml
services:
  zookeeper:
    ...
    environment:
    	- ALLOW_ANONYMOUS_LOGIN=yes
    	- ZOO_INIT_LIMIT=10
    ...
```



### TLS配置参数

如：本地`/tmp/cert`目录中包含`zookeeper`子目录，并存在相应的证书文件。

Docker 命令行方式时类似命令如下：

```console
$ docker run -d --name zookeeper \
    -v /tmp/cert:/srv/cert \
    -e ALLOW_ANONYMOUS_LOGIN=yes \
    -e ZOO_TLS_CLIENT_ENABLE=yes \
    -e ZOO_TLS_PORT_NUMBER=3181 \
    -e ZOO_TLS_CLIENT_KEYSTORE_FILE=/srv/cert/zookeeper/zookeeper.key \
    -e ZOO_TLS_CLIENT_TRUSTSTORE_FILE=/srv/cert/zookeeper/zookeeper.crt \
    colovu/zookeeper:latest
```

Docker-Compose 方式时，YAML 文件中存在类似如下内容：

```yaml
services:
  zookeeper:
  ...
    environment:
      ...
      - ALLOW_ANONYMOUS_LOGIN=yes
      - ZOO_TLS_CLIENT_ENABLE=yes
      - ZOO_TLS_PORT_NUMBER=3181
      - ZOO_TLS_CLIENT_KEYSTORE_FILE=/srv/cert/zookeeper/zookeeper.key
      - ZOO_TLS_CLIENT_TRUSTSTORE_FILE=/srv/cert/zookeeper/zookeeper.crt
    volumes:
      - /tmp/cert:/srv/cert
  ...
```

> 注意：
>
> - /tmp/cert 中需要包含 zookeeper 子目录，且相应证书文件存放在该位置；文件权限需要为`400`
> - `/srv/cert/zookeeper/...` 指的是容器内的路径，不可以修改



### 应用已有配置文件

应用配置文件默认存储在容器内：`/srv/conf/zookeeper/zoo.cfg`。

#### 使用已有配置文件

zookeeper 容器的配置文件默认存储在数据卷`/srv/conf`中，文件名及子路径为`zookeeper/zoo.cfg`。有以下两种方式可以使用自定义的配置文件：

- 直接映射配置文件

```shell
$ docker run -d --restart always --name zoo1 -v $(pwd)/zoo.cfg:/srv/conf/zookeeper/zoo.cfg colovu/zookeeper:latest
```

- 映射配置文件数据卷

```shell
$ docker run -d --restart always --name zoo1 -v $(pwd):/srv/conf colovu/zookeeper:latest
```

> 使用数据卷映射方式时：
>
> - 本地路径中需要包含 zookeeper 子目录，且相应文件存放在该目录中
> - `zookeeper`子目录中需要存在文件`.app_init_flag`；如果不存在该文件，则会使用默认的环境变量值及用户自定义的环境变量值重新初始化配置文件



### 手动修改配置文件

对于没有本地配置文件的情况，可以使用以下方式进行配置。

#### 使用镜像初始化容器

使用宿主机目录映射容器数据卷，并初始化容器：

```shell
$ docker run -d -v /tmp/conf:/srv/conf colovu/zookeeper:latest
```

或使用 Docker-Compose 方式:

```yaml
version: '3.6'

services:
  zookeeper:
    image: 'colovu/zookeeper:latest'
    volumes:
      - /tmp/conf:/srv/conf
```

#### 修改配置文件

在宿主机中修改映射目录下子目录`zookeeper`中文件`zoo.cfg`：

```shell
$ vi /tmp/conf/zookeeper/zoo.cfg
```

#### 重新启动容器

在修改配置文件后，重新启动容器，以使修改的内容起作用：

```shell
$ docker restart zookeeper
```

或者使用 Docker Compose：

```shell
$ docker-compose restart zookeeper
```



## 安全

### 用户认证

Zookeeper 镜像默认禁用了无密码访问功能，在实际生产环境中建议使用用户名及密码控制访问；如果为了测试需要，可以使用以下环境变量启用无密码访问功能：

```shell
ALLOW_ANONYMOUS_LOGIN=yes
```



通过配置环境变量`ZOO_ENABLE_AUTH`，可以启用基于 SASL/Digest-MD5 加密的用户认证功能。在启用用户认证时，同时需要通过`ZOO_CLIENT_USER` 与 `ZOO_CLIENT_PASSWORD` 环境变量设置允许登录的用户名及密码。

> 启用认证后，用户使用 CLI 工具`zkCli.sh`时，也需要进行认证，可通过`. /usr/local/bin/entrypoint.sh`来使用环境变量中的默认密码。

命令行使用参考：

```shell
$ docker run -d -e ZOO_ENABLE_AUTH=yes \
		-e ZOO_SERVER_USERS=user1,user2 \
    -e ZOO_SERVER_PASSWORDS=pass4user1,pass4user2 \
    -e ZOO_CLIENT_USER=user1 \
    -e ZOO_CLIENT_PASSWORD=pass4user1 \
    colovu/zookeeper:latest
```

使用 Docker Compose 时，`docker-compose.yml`应包含类似如下配置：

```yaml
services:
  zookeeper:
  ...
    environment:
      - ZOO_ENABLE_AUTH=yes
      - ZOO_SERVER_USERS=user1,user2
      - ZOO_SERVER_PASSWORDS=pass4user1,pass4user2
      - ZOO_CLIENT_USER=user1
      - ZOO_CLIENT_PASSWORD=pass4user1
  ...
```



## 日志

默认情况下，Docker镜像配置为将容器日志直接输出至`stdout`，可以使用以下方式查看：

```bash
$ docker logs zookeeper
```

使用 Docker Compose 管理时，使用以下命令：

```bash
$ docker-compose logs zookeeper
```

实际使用时，可以配置将相应应用日志信息输出至`/var/log`或`/srv/datalog`数据卷的相应文件中。配置方式使用 `ZOO_LOG4J_PROP` 环境变量在容器实例化时进行配置，类似如下：

```shell
$ docker run -d --restart always --name zookeeper -e ZOO_LOG4J_PROP="INFO,ROLLINGFILE" colovu/zookeeper:latest
```

使用该配置后，相应的系统日志文件，将会存储在数据卷`/var/log`的 子目录`zookeeper`中。

如果需要同时输出至终端和日志文件，可设置环境变量类似为：`ZOO_LOG4J_PROP="INFO,CONSOLE,ROLLINGFILE"`

容器默认使用的日志驱动为 `json-file`，如果需要使用其他驱动，可以使用`--log-driver`进行修改；更多有关日志的使用帮助，可参考文档 [ZooKeeper Logging](https://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_logging) 中更多说明。



## 容器维护

### 容器数据备份

默认情况下，镜像都会提供`/srv/data`数据卷持久化保存数据。如果在容器创建时，未映射宿主机目录至容器，需要在删除容器前对数据进行备份，否则，容器数据会在容器删除后丢失。

如果需要备份数据，可以使用按照以下步骤进行：

#### 停止当前运行的容器

Docker 命令行方式时，可以使用以下命令停止：

```bash
$ docker stop zookeeper
```

Docker Compose 方式时，可以使用以下命令停止：

```bash
$ docker-compose stop zookeeper
```

#### 执行备份命令

在宿主机创建用于备份数据的目录`/tmp/back-up`，并执行文件复制命令。

Docker 命令行方式时，类似以下命令：

```bash
$ docker run --rm -v /tmp/back-up:/backups --volumes-from zookeeper busybox \
  cp -a /srv/data/zookeeper /backups/
```

Docker Compose 方式时，类似以下命令：

```bash
$ docker run --rm -v /tmp/back-up:/backups --volumes-from `docker-compose ps -q zookeeper` busybox \
  cp -a /srv/data/zookeeper /backups/
```

> - `--volumes-from zookeeper` ：映射 zookeeper 容器的数据卷至新启动的容器中
> - `docker-compose ps -q zookeeper`：使用命令获取 zookeeper 容器名，也可直接指定
> - `busybox`：新启动的 busybox 容器，并使用该容器的命令进行数据拷贝

### 容器数据恢复

在容器创建时，如果未映射宿主机目录至容器数据卷，则容器会创建私有数据卷。如果是启动新的容器，可直接使用备份的数据进行数据卷映射，命令类似如下：

```bash
$ docker run -v /tmp/back-up:/srv/data colovu/zookeeper:latest
```

使用 Docker Compose 管理时，可直接在`docker-compose.yml`文件中指定：

```yaml
zookeeper:
  ...
	volumes:
		- /tmp/back-up:/srv/data
  ...
```



### 镜像更新

针对当前镜像，会根据需要不断的提供更新版本。针对更新版本（大版本相同的情况下，如果大版本不同，需要参考指定说明处理），可使用以下步骤使用新的镜像创建容器：

#### 获取新版本的镜像

```bash
$ docker pull colovu/zookeeper:TAG
```

这里`TAG`为指定版本的标签名，如果使用最新的版本，则标签为`latest`。

#### 停止容器并备份数据

如果容器未使用宿主机目录映射为容器数据卷的方式创建，参照`容器数据备份`中方式，备份容器数据。

如果容器使用宿主机目录映射为容器数据卷的方式创建，不需要备份数据。

#### 删除当前使用的容器

```bash
$ docker rm -v zookeeper
```

使用 Docker Compose 管理时，使用以下命令：

```bash
$ docker-compose rm -v zookeeper
```

#### 使用新的镜像启动容器

将宿主机备份目录映射为容器数据卷，并创建容器：

```bash
$ docker run --name zookeeper -v /tmp/back-up:/srv/data colovu/zookeeper:TAG
```

使用 Docker Compose 管理时，确保`docker-compose.yml`文件中包含数据卷映射指令，使用以下命令启动：

```bash
$ docker-compose up zookeeper
```



## Docker-Compose 一键更新

如果容器使用了数据卷的持久化，可以使用以下命令，一键更新服务容器：

```shell
$ docker-compose pull zookeeper && docker-compose up -d --force-recreate zookeeper
```

- 如果没有使用数据卷映射，则数据会丢失

  

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

