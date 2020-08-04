# Docker 常用基础操作命令

如有疑问，可参照官方说明文档。



## Docker 系列命令

以下使用`colovu/redis:latest`做样例，使用时需要对应修改。



### docker pull

拉取一个指定的镜像至本地。

```shell
# 拉取默认`latest`版本（可省略TAG信息）
$ docker pull colovu/redis

# 拉取指定版本，如 5.0
$ docker pull colovu/redis:5.0
```

### docker images

显示本地已下载的镜像信息。

```shell
# 显示所有镜像信息
$ docker images

# 显示指定应用的镜像信息
$ docker images | grep redis
```

### docker run

使用指定镜像初始化并启动一个容器。

```shell
# 使用默认参数以任务方式启动
$ docker run -d colovu/redis:latest

# 使用交互式启动
$ docker run -it --rm --name redis colovu/redis:latest

# 指定映射端口、宿主机映射目录启动
$ docker run -d -e ALLOW_EMPTY_PASSWORD=yes -p 6379:6379 -v /tmp/data:/srv/data -v /tmp/conf:/srv/conf colovu/redis:latest
```

- `-d`：指定以后台服务方式启动容器
- `-it`：指定以交互方式启动容器，并制定交互终端
- `--rm`：容器退出时删除容器数据
- `--name`：为运行中的容器命名，其他容器操作命令可以以该名字进行相应操作
- `-p`：指定宿主机与容器端口映射关系。可以为范围，如：8000-9000:8000-9000
- `-v`：指定宿主机目录与容器内数据卷映射关系
- `-e`：设置容器启动时传入容器内的环境变量

### docker ps

查看运行中的容器列表。

```shell
# 查看所有容器
$ docker ps

# 查看指定容器(按规则过滤）
$ docker ps | grep redis
```

### docker stop

停止一个指定的容器。

```shell
# 可使用运行中的容器名来停止
$ docker stop redis

# 也可以使用运行中的容器ID来停止（可使用 `docker ps` 查看）
$ docker stop f60ad46424b5
```

### docker start

启动一个停止的容器。

```shell
# 可使用已停止的容器名来停止
$ docker start redis

# 也可以使用已停止的容器ID来停止（可使用 `docker container ls -a` 查看）
$ docker start f60ad46424b5
```

### docker restart

重新启动运行一个运行中的容器。

```shell
$ docker restart redis
$ docker restart f60ad46424b5
```

### docker exec

链接至一个指定的容器，并运行相应命令。

```shell
# 使用运行中的容器名
$ docker exec -it redis /bin/bash

# 可以使用运行中的容器ID（可使用 `docker ps` 查看）
$ docker exec -it  f60ad46424b5 /bin/bash
```

- `-it`：指定使用交互方式启动
- `/bin/bash`：在容器中运行的命令

### docker attach

链接至一个运行中的指定容器，显示相应信息。attach 方式无法执行其他命令。

```shell
# 指定窗口关闭时，不停止运行中的容器
$ docker attach --sig-proxy=false redis

# attach 窗口关闭，则相应的容器被停止
$ docker attach redis
```

- `--sig-proxy=false`：attach 一个容器时，则打开的窗口如同使用`docker run -it`方式启动容器的窗口，如果不设置该参数，则窗口关闭，容器停止

### docker logs

显示一个指定容器的日志信息。这里日志指的是容器输出至标准输出的日志。

```shell
$ docker logs redis
$ docker logs f60ad46424b5
```

### docker port

查看指定运行中容器映射的端口信息。

```shell
$ docker port redis
```

### docker rm

删除一个停止的容器。

```shell
$ docker rm redis
$ docker rm f60ad46424b5
```

### docker rmi

删除一个镜像。删除镜像前，需要确认应没有依赖该镜像的容器（运行中或停止的）。

```shell
$ docker rmi colovu/redis:latest
```



## Docker-Compose 系列命令

假设在当前目录中存在配置文件`docker-compose.yml`文件，且该文件中定义了`redis`服务。

如果配置文件不是该名称，需要使用`-f file-name.yml`来指定具体的文件名。

如以下配置文件定义了 `redis`/`prometheus`/`postgres`三个服务。

```yaml
version: '3.6'

services:
  prometheus:
    image: 'colovu/prometheus:latest'
    restart: always

  postgres:
    image: 'colovu/postgres:latest'
    restart: always
    environment:
      - PG_USERNAME=postgres
      - PG_PASSWORD=123

  redis:
    image: 'colovu/redis:latest'
    restart: always
    environment:
      - REDIS_PASSWORD=konka

```



### docker-compose pull

下载配置文件中相应服务对应的镜像文件。

```shell
# 下载所有已定义服务的指定版本镜像
$ docker-compose pull

# 仅下载多个服务中指定服务的镜像(使用定义的服务名)
$ docker-compose pull redis
```

### docker-compose up

启动配置文件中所有服务或指定服务。

```shell
# 以后台方式启动所有服务
$ docker-compose up -d

# 以后台方式启动指定服务（会自动启动依赖的服务）
$ docker-compose up -d redis

# 以前台方式启动指定服务（不建议）
$ docker-compose up -it redis

# 重新创建指定的容器（一般在重新拉取镜像后，使用重新创建容器以保证容器使用了最新的镜像）
$ docker-compose up -d --force-recreate redis
```

> 注意：`--force-recreate` 命令执行时，并不会自动重新根据之前的扩容指令创建新的容器；如果`recreate`之前从一个容器扩容为了三个容器，则`recreate`之后，只会有一个容器运行

### docker-compose down

停止配置文件中定义的服务并删除容器。

```shell
$ docker-compose down
```

### docker-compose ps

查看运行中的容器列表。

```shell
$ docker-compose ps
```

### docker-compose start

根据配置文件定义，启动一个停止的容器服务。

```shell
$ docker-compose start redis
```

### docker-compose stop

根据配置文件定义，停止一个启动的容器服务。

```shell
$ docker-compose stop redis
```

### docker-compose restart

根据配置文件定义，重新启动一个已初始化的容器服务。

```shell
$ docker-compose restart redis
```

### docker-compose logs

根据配置文件定义，查看一个指定容器服务的运行日志。

```shell
$ docker-compose logs redis
```

### docker-compose exec

链接至一个指定的服务，并运行相应命令。

```shell
$ docker-compose exec redis ls
```

### docker-compose port

查看指定服务的端口映射信息。

```shell
$ docker-compose port redis
```

### docker-compose rm

删除一个服务对应的容器(已停止的)。

```shell
$ docker-compose rm redis
```

### docker-compose scale

根据配置文件，缩容或扩容一个指定的服务。

```shell
# 扩容 redis 服务为三个容器（包含原有的容器）
$ docker-compose scale redis=3

# 缩容 redis 服务为两个容器
$ docker-compose scale redis=2
```

- 如果定义的新的服务容器数量比原来多，则是扩容；如果定义的比原来少，则是缩容
- 一个命令中可同时定义多个服务的缩容或扩容



----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))

