# 基于 Docker 的 Redis 单机配置与使用

使用的镜像基本信息：colovu/redis:latest

在实际使用过程中，如果需要使用其他版本的镜像，请按照需要替换相关下载镜像的命令中对应的镜像 TAG。



## 基本约定

### 端口

- 6379：Redis 业务客户端访问端口
- 6380：Redis 业务客户端访问端口（TLS）

### 数据卷

镜像默认提供以下数据卷定义，默认数据分别存储在自动生成的`redis`子目录中：

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



## 基于 Docker 命令行

### 下载镜像

可以不单独下载镜像，如果镜像不存在，会在初始化容器时自动下载。

```shell
$ docker pull colovu/redis:latest
```



### 实例化服务容器

生成并运行一个新的容器：

```shell
$ docker run -d --name redis -p 6379:6379 -e ALLOW_EMPTY_PASSWORD=yes colovu/redis:latest
```

- `-d`: 使用服务方式启动容器
- `--name redis`: 为当前容器命名
- `-e ALLOW_EMPTY_PASSWORD=yes`: 设置默认允许任意用户登录（调试时使用，生产系统应当使用密码认证）



如果需要数据持久化，可以使用数据卷映射生成并运行一个容器：

```shell

 
 $ docker run -d --name redis -p 6379:6379 -e ALLOW_EMPTY_PASSWORD=yes \
  -v /tmp/data:/srv/data \
  -v /tmp/conf:/srv/conf \
  colovu/redis:latest
```

- `/tmp/data`：存储 Redis 缓存数据
- `/tmp/conf`：存储容器配置文件

> 注意：将数据持久化存储至宿主机，可避免容器销毁导致的数据丢失。同时，将数据存储及数据日志分别映射为不同的本地设备（如不同的共享数据存储）可提供较好的性能保证。



### 查看容器状态

查看当前运行的所有容器：

```shell
$ docker ps
```

![docker-single-ps](img/redis-single-ps.png)

查看指定容器的日志（容器shell脚本输出的日志信息）：

```shell
# 使用启动时定义的容器名或容器 ID
$ docker logs redis
$ docker logs 0a8d4ab79f92
```



### 验证容器可用性

链接容器：

```shell
# 使用启动时定义的容器名或容器 ID
$ docker exec -it redis /bin/bash
$ docker exec -it 0a8d4ab79f92 /bin/bash
```



在容器中使用`redis-cli`启动客户端，使用`ping`命令或`set`命令进行数据操作，验证服务可用性：

![docker-single-ping](img/redis-single-ping.png)

退出链接的容器：

![docker-single-exit](img/redis-single-exit.png)

可另外启动新的窗口，链接至容器，查看之前设置的数据：

![docker-single-get](img/redis-single-get.png)



### 链接至容器并使用

启用 [Docker container networking](https://docs.docker.com/engine/userguide/networking/)后，基于同一网络的容器间互相通讯时，可以直接使用已定义的容器名进行链接后使用。

如之前的容器启动命令中包含网络设置：

```shell
$ docker run -d --name redis --network back-tier -p 6379:6379 \
	-e ALLOW_EMPTY_PASSWORD=yes colovu/redis:latest
```

- `back-tier`： 之前已创建的容器网络



```shell
$ docker run -d --name other-app --network back-tier \
	--link redis:redis.server other-app-image:tag
```

- `--link redis:redis.server`: 连接运行中的`redis`容器，并命名为`redis.server`供`app-name`内应用使用（如 容器中应用使用`redis.server`进行寻址访问）



### 其他容器操作

以下命令中的容器指定，可以使用容器名（如 redis ），也可以使用容器 ID （如 0a8d4ab79f92 ）：

```shell
# 停止容器
$ docker stop redis

# 启动容器
$ docker start redis

# 删除已停止的容器
$ docker rm redis

# 重启容器
$ docker restart redis
```



## 基于 Docker-Compose 命令

使用配置文件`docker-compose-test.yml`:

```yaml
version: '3.6'

services:
  redis:
    image: 'colovu/redis:latest'
    ports:
    	- 6379:6379
    environment:
    	- ALLOW_EMPTY_PASSWORD=yes
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
$ docker-compose -f docker-compose-test.yml up -d redis
```

- 如果配置文件命名为`docker-compose.yml`，可以省略`-f docker-compose-test.yml`参数



如果需要数据持久化，可以使用已存在的宿主机目录映射为容器数据卷，生成并运行容器；YAML 文件包含类似如下内容：

```yaml
services:
  redis:
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
# 使用已定义的容器名（如之前启动时使用`--name redis`命名的容器）
$ docker-compose -f docker-compose-test.yml logs redis

# 使用容器 ID（如之前`docker ps`查询出的容器 ID）
$ docker-compose -f docker-compose-test.yml logs 0a8d4ab79f92
```



### 验证容器可用性

验证操作可参考 `基于 Docker 命令行`中对应小结；除可以使用 Docker 命令对容器（容器名或容器 ID）进行操作外，也可以使用 Docker-Compose 命令对容器进行操作（以下命令默认配置文件名为`docker-compose.yml`）：

```shell
# exec 命令不需要指定交互模式的参数`-it`
$ docker-compose exec redis /bin/bash
```



### 链接至容器并使用

在一个 YAML 文件中定义的各个服务之间，默认是基于同一个网络，可以直接使用服务名进行互相访问。

```yaml
version: '3.6'

services:
  redis:
    image: 'colovu/redis:latest'
    ports:
    	- 6379:6379
    environment:
    	- ALLOW_EMPTY_PASSWORD=yes
    	
  myapp:
    image: 'other-app-img:tag'
    links:
    	- redis:redis.server
```

- `redis:redis.server`： 如果其他容器中定义的访问主机名与服务名不一致，可以以`link`的方式定义新的名字（如，新的应用中以`redis.server`主机名进行寻址访问）



### 其他容器操作

以下命令中的配置文件，默认为`docker-compose.yml`；容器指定，可以使用服务名（如 redis ），也可以使用容器 ID 或容器名（如 0a8d4ab79f92 ）：

```shell
# 停止所有服务，并删除容器
$ docker-compose down

# 重新创建并启动所有服务容器（或指定服务）
$ docker-compose up -d --force-recreate 
$ docker-compose up -d --force-recreate redis

# 停止指定服务容器
$ docker-compose stop redis

# 启动指定服务容器
$ docker-compose start redis

# 删除已停止的容器
$ docker-compose rm redis

# 重启服务容器
$ docker-compose restart redis
```



## 容器配置

在初始化 redis 容器时，如果应用默认配置文件不存在，可以在初始化容器时使用相应参数对默认参数进行修改。

Docker 命令行方式时类似命令如下：

```shell
$ docker run -d --restart always -e "REDIS_INIT_LIMIT=10" --name redis colovu/redis:latest
```

Docker-Compose 方式时，增加`environment:`定义，YAML 文件中存在类似如下内容：

```yaml
services:
  redis:
    ...
    environment:
    	- ALLOW_EMPTY_PASSWORD=yes
    ...
```



### SSL配置参数

当使用 TLS 时，则默认的 non-TLS 通讯被禁用。如果需要同时支持 TLS 与 non-TLS 通讯，可以使用参数`REDIS_TLS_PORT`配置容器使用不同的 TLS 端口。

如：本地`/tmp/cert`目录中包含`redis`子目录，并存在相应的证书文件。

Docker 命令行方式时类似命令如下：

```console
$ docker run --name redis \
    -v /tmp/cert:/srv/cert \
    -e ALLOW_EMPTY_PASSWORD=yes \
    -e REDIS_TLS_ENABLED=yes \
    -e REDIS_TLS_PORT=6380 \
    -e REDIS_TLS_CERT_FILE=/srv/cert/redis/redis.crt \
    -e REDIS_TLS_KEY_FILE=/srv/cert/redis/redis.key \
    -e REDIS_TLS_CA_FILE=/srv/cert/redis/redisCA.crt \
    colovu/redis:latest
```

Docker-Compose 方式时，YAML 文件中存在类似如下内容：

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



### 应用已有配置文件

应用配置文件默认存储在容器内：`/srv/conf/redis/redis.conf`。

#### 使用已有配置文件

Redis 容器的配置文件默认存储在数据卷`/srv/conf`中，文件名及子路径为`redis/redis.conf`。有以下两种方式可以使用自定义的配置文件：

- 直接映射配置文件

```shell
$ docker run -d --restart always --name redis -v $(pwd)/redis.conf:/srv/conf/redis/redis.conf colovu/redis:latest
```

- 映射配置文件数据卷

```shell
$ docker run -d --restart always --name redis -v $(pwd):/srv/conf colovu/redis:latest
```

> 使用数据卷映射方式时：
>
> - 本地路径中需要包含 redis 子目录，且相应文件存放在该目录中
> - `redis`子目录中需要存在文件`.app_init_flag`；如果不存在该文件，则会使用默认的环境变量值及用户自定义的环境变量值重新初始化配置文件



### 手动修改配置文件

对于没有本地配置文件的情况，可以使用以下方式进行配置。

#### 使用镜像初始化容器

使用宿主机目录映射容器数据卷，并初始化容器：

```shell
$ docker run -d --restart always --name redis -v /tmp/conf:/srv/conf colovu/redis:latest
```

或使用 Docker-Compose 方式:

```yaml
version: '3.6'

services:
  redis:
    image: 'colovu/redis:latest'
    ports:
      - '6379'
    volumes:
      - /tmp/conf:/srv/conf
```

#### 修改配置文件

在宿主机中修改映射目录下子目录`redis`中文件`redis.conf`：

```shell
$ vi /tmp/conf/redis/redis.conf
```

#### 重新启动容器

在修改配置文件后，重新启动容器，以使修改的内容起作用：

```shell
$ docker restart redis
```

或者使用 Docker Compose：

```shell
$ docker-compose restart redis
```



## 安全

### 用户认证

Redis 镜像默认禁用了无密码访问功能，在实际生产环境中建议使用用户名及密码控制访问；如果为了测试需要，可以使用以下环境变量启用无密码访问功能：

```shell
ALLOW_EMPTY_PASSWORD=yes
```



通过配置环境变量`REDIS_PASSWORD`，可以启用基于密码的用户认证功能。

Docker 命令行方式参考：

```shell
$ docker run -it -e REDIS_PASSWORD=colovu colovu/redis:latest
```

Docker Compose 方式时，`docker-compose.yml`应包含类似如下配置：

```yaml
services:
  redis:
  ...
    environment:
      - REDIS_PASSWORD=colovu
  ...
```



## 容器维护

### 容器数据备份

默认情况下，镜像都会提供`/srv/data`数据卷持久化保存数据。如果在容器创建时，未映射宿主机目录至容器，需要在删除容器前对数据进行备份，否则，容器数据会在容器删除后丢失。

如果需要备份数据，可以使用按照以下步骤进行：

#### 停止当前运行的容器

Docker 命令行方式时，可以使用以下命令停止：

```bash
$ docker stop redis
```

Docker Compose 方式时，可以使用以下命令停止：

```bash
$ docker-compose stop redis
```

#### 执行备份命令

在宿主机创建用于备份数据的目录`/tmp/back-up`，并执行文件复制命令。

Docker 命令行方式时，类似以下命令：

```bash
$ docker run --rm -v /tmp/back-up:/backups --volumes-from redis busybox \
  cp -a /srv/data/redis /backups/
```

Docker Compose 方式时，类似以下命令：

```bash
$ docker run --rm -v /tmp/back-up:/backups --volumes-from `docker-compose ps -q redis` busybox \
  cp -a /srv/data/redis /backups/
```

> - `--volumes-from redis` ：映射 redis 容器的数据卷至新启动的容器中
> - `docker-compose ps -q redis`：使用命令获取 redis 容器名，也可直接指定
> - `busybox`：新启动的 busybox 容器，并使用该容器的命令进行数据拷贝

### 容器数据恢复

在容器创建时，如果未映射宿主机目录至容器数据卷，则容器会创建私有数据卷。如果是启动新的容器，可直接使用备份的数据进行数据卷映射，命令类似如下：

```bash
$ docker run -v /tmp/back-up:/srv/data colovu/redis:latest
```

使用 Docker Compose 管理时，可直接在`docker-compose.yml`文件中指定：

```yaml
redis:
  ...
	volumes:
		- /tmp/back-up:/srv/data
  ...
```



### 镜像更新

针对当前镜像，会根据需要不断的提供更新版本。针对更新版本（大版本相同的情况下，如果大版本不同，需要参考指定说明处理），可使用以下步骤使用新的镜像创建容器：

#### 获取新版本的镜像

```bash
$ docker pull colovu/redis:TAG
```

这里`TAG`为指定版本的标签名，如果使用最新的版本，则标签为`latest`。

#### 停止容器并备份数据

如果容器未使用宿主机目录映射为容器数据卷的方式创建，参照`容器数据备份`中方式，备份容器数据。

如果容器使用宿主机目录映射为容器数据卷的方式创建，不需要备份数据。

#### 删除当前使用的容器

```bash
$ docker rm -v redis
```

使用 Docker Compose 管理时，使用以下命令：

```bash
$ docker-compose rm -v redis
```

#### 使用新的镜像启动容器

将宿主机备份目录映射为容器数据卷，并创建容器：

```bash
$ docker run --name redis -v /tmp/back-up:/srv/data colovu/redis:TAG
```

使用 Docker Compose 管理时，确保`docker-compose.yml`文件中包含数据卷映射指令，使用以下命令启动：

```bash
$ docker-compose up redis
```



## Docker-Compose 一键更新

如果容器使用了数据卷的持久化，可以使用以下命令，一键更新服务容器：

```shell
$ docker-compose pull redis && docker-compose up -d --force-recreate redis
```

- 如果没有使用数据卷映射，则数据会丢失

  

## 注意事项

### 容器中应用运行方式

- 容器中 Redis 启动参数不能配置为后台运行，只能使用前台运行方式，即：`daemonize no`



### 持久化数据存储

如果需要将容器数据持久化存储至宿主机或数据存储中，需要确保宿主机对应的路径存在，并在启动时，映射为对应的数据卷。

Redis 镜像默认配置了用于存储数据的数据卷 `/srv/data`及用于存储配置文件的数据卷`/srv/conf`。可以使用宿主机目录映射相应的数据卷，将数据持久化存储在宿主机中。路径中，应用对应的子目录如果不存在，容器会在初始化时创建，并生成相应的默认文件。

> 注意：将数据持久化存储至宿主机，可避免容器销毁导致的数据丢失。同时，将数据存储及数据日志分别映射为不同的本地设备（如不同的共享数据存储）可提供较好的性能保证。



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

