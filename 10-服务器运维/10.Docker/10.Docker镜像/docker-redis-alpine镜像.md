# 简介

REmote DIctionary Server(Redis) 是一个由Salvatore Sanfilippo写的key-value存储系统。

Redis是一个开源的使用ANSI C语言编写、遵守BSD协议、支持网络、可基于内存亦可持久化的日志型、Key-Value数据库，并提供多种语言的API。

它通常被称为数据结构服务器，因为值（value）可以是 字符串(String), 哈希(Hash), 列表(list), 集合(sets) 和 有序集合(sorted sets)等类型。

**Redis 优势**

- 性能极高 – Redis能读的速度是110000次/s,写的速度是81000次/s 。
- 丰富的数据类型 – Redis支持二进制案例的 Strings, Lists, Hashes, Sets 及 Ordered Sets 数据类型操作。
- 原子 – Redis的所有操作都是原子性的，意思就是要么成功执行要么失败完全不执行。单个操作是原子性的。多个操作也支持事务，即原子性，通过MULTI和EXEC指令包起来。
- 丰富的特性 – Redis还支持 publish/subscribe, 通知, key 过期等等特性。
- 数据的持久化 – 可以将内存中的数据保存在磁盘中，重启的时候可以再次加载进行使用。



Git仓库地址：https://github.com/endial/docker-redis-alpine



## 差异介绍

当前镜像跟随官方主要镜像版本进行不定期更新，与官方镜像差异主要为：

- 修改默认用户及分组信息
- 修改默认数据存储目录为：`/srv/data/redis`
- 增加默认数据卷
- 修改镜像创建命令，减少镜像层数
- 增加初始化配置文件至数据卷操作

具体使用文档可参照[仓库说明文档](https://github.com/endial/docker-redis-alpine/README.md)。



## Dockerfile文件

Dockerfile文件如下：

```dockerfile
FROM endial/base-alpine:v3.11

ENV REDIS_VERSION 5.0.8
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-5.0.8.tar.gz
ENV REDIS_DOWNLOAD_SHA f3c7eac42f433326a8d981b50dba0169fdfaf46abb23fcda2f933a7552ee4ed7

RUN addgroup -S -g 1000 redis; \
	adduser -S -G redis -u 1000 redis; \
	\
	mkdir -p /srv/data/redis; \
	mkdir -p /etc/redis; \
	chown redis:redis /srv/data/redis; \
	\
	apk add --no-cache \
		'su-exec>=0.2' \
		tzdata \
	; \
	\
	set -eux; \
	\
	apk add --no-cache --virtual .build-deps \
		coreutils \
		gcc \
		linux-headers \
		make \
		musl-dev \
		openssl-dev \
	; \
	\
	wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL"; \
	echo "$REDIS_DOWNLOAD_SHA *redis.tar.gz" | sha256sum -c -; \
	mkdir -p /usr/src/redis; \
	tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1; \
	rm redis.tar.gz; \
	\
# disable Redis protected mode [1] as it is unnecessary in context of Docker
# (ports are not automatically exposed when running inside Docker, but rather explicitly by specifying -p / -P)
# [1]: https://github.com/antirez/redis/commit/edd4d555df57dc84265fdfb4ef59a4678832f6da
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /usr/src/redis/src/server.h; \
	sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /usr/src/redis/src/server.h; \
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /usr/src/redis/src/server.h; \
# for future reference, we modify this directly in the source instead of just supplying a default configuration flag because apparently "if you specify any argument to redis-server, [it assumes] you are going to specify everything"
# see also https://github.com/docker-library/redis/issues/4#issuecomment-50780840
# (more exactly, this makes sure the default behavior of "save on SIGTERM" stays functional by default)
	\
	make -C /usr/src/redis -j "$(nproc)" all; \
	make -C /usr/src/redis install; \
	\
# TODO https://github.com/antirez/redis/pull/3494 (deduplicate "redis-server" copies)
	serverMd5="$(md5sum /usr/local/bin/redis-server | cut -d' ' -f1)"; export serverMd5; \
	find /usr/local/bin/redis* -maxdepth 0 \
		-type f -not -name redis-server \
		-exec sh -eux -c ' \
			md5="$(md5sum "$1" | cut -d" " -f1)"; \
			test "$md5" = "$serverMd5"; \
		' -- '{}' ';' \
		-exec ln -svfT 'redis-server' '{}' ';' \
	; \
	\
	cp -rf /usr/src/redis/*.conf /etc/redis/ \
	rm -r /usr/src/redis; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-network --virtual .redis-rundeps $runDeps; \
	apk del --no-network .build-deps; \
	\
	redis-cli --version; \
	redis-server --version

VOLUME [ "/srv/data", "/var/log", "/var/run" ]
EXPOSE 6379

WORKDIR /srv/data/redis

COPY redis /etc/
ENTRYPOINT ["/etc/redis/entrypoint.sh"]

CMD ["redis-server"]
```



### 镜像管理

创建镜像：

```shell
docker build -t endial/redis-alpine:v5.0.8 .
```



上传镜像至Docker Hub：

```shell
docker push endial/redis-alpine:v5.0.8
```



获取镜像：

```shell
docker pull endial/redis-alpine:v5.0.8
```





----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))

