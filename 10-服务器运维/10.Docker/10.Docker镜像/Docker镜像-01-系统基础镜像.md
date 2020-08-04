# 简介



如果没有特定需求，可以直接使用各操作系统的官方镜像，如 debian / centos / ubuntu / alpine 等。

之所以制作系统基础镜像，是为了后续制作相关的应用软件镜像做准备，目的如下：

- 各软件镜像使用统一的基础系统镜像，减少部署时需要拉取的镜像数量，减少部署时间
- 使用统一的基础镜像，同时，基于同样的规则开发应用镜像，使各软件镜像使用操作具备相似性，降低镜像使用复杂度
- 在基础镜像中增加通用软件，降低新开发应用镜像的体积

相关系统镜像，刻在 [Docker Hub](https://hub.docker.com) 上搜索到对应发布信息。



## 系统镜像

### Debian

#### 基本信息

**镜像地址：** colovu/debian:latest

**版本信息：** 9-stretch、10-buster、latest

**代码地址：** [Gitee](https://gitee.com/colovu/docker-debian) / [Github](https://github.com/colovu/docker-debian)

**与官方镜像差异：**

- 增加 `default、tencent、ustc、aliyun、huawei` 源配置文件，可在编译时通过 `ARG` 变量`apt_source`进行选择
- 更新已安装的软件包至镜像发布时的最新版本
- 增加`locales`，并设置默认编码格式为`en_US.utf8`
- 增加`gosu`工具
- 设置默认时区信息为 `Asia/Shanghai`



### Alpine

#### 基本信息

**镜像地址：** colovu/alpine:latest

**版本信息：** 3.11、3.12、latest

**代码地址：** [Gitee](https://gitee.com/colovu/docker-alpine) / [Github](https://github.com/colovu/docker-alpine)

**与官方镜像差异：**

- 增加 `default、tencent、ustc、aliyun、huawei` 源配置文件，可在编译时通过 `ARG` 变量`apt_source`进行选择
- 更新已安装的软件包至镜像发布时的最新版本
- 增加`bash`工具
- 增加`gosu`工具



## 系统镜像使用

以 Debian 10 系统 `latest` 版本镜像为例，说明基本镜像的相关使用参考。其他系统，操作有一定相似性。

### 本地使用

镜像获取：

```shell
# 拉取镜像
$ docker pull colovu/debian:latest

# 查看当前本地镜像列表
$ docker images
```



使用系统镜像启动一个容器做验证及测试：

```shell
$ docker run -it --rm colovu/debian:latest /bin/bash
```

- `-it`：使用交互式终端启动容器
- `--rm`：退出时删除容器
- `colovu/debian:latest`：包含版本信息的镜像名称
- `/bin/bash`：在容器中执行`/bin/bash`命令；如果不执行命令，容器会在启动后立即结束并退出。

容器的持续存在，需要容器中运行一个持续的进程。基础系统镜像基本都未启动类似的进程，因此，常规使用`-it`方式启动`/bin/bash`软件，进行交互式使用。



### 镜像开发使用

使用当前基础系统镜像做应用镜像开发时，参考 Dockerfile 片段如下：

```shell
FROM colovu/debian:10

# ARG参数使用"--build-arg"指定，如 "--build-arg apt_source=tencent"
# sources.list 可使用版本：default / tencent / ustc / aliyun / huawei
ARG apt_source=default

# 镜像内相应应用及依赖软件包的安装脚本
RUN \
# 更改源为当次编译指定的源
	cp /etc/apt/sources.list.${apt_source} /etc/apt/sources.list; \
	...
```



应用软件镜像 Dockerfile 包含以上类似片段时，镜像编译命令可通过以下方式，指定当前使用的源，以加快编译速度。如使用 Tencent 提供的源编译`redis`应用的latest`版本镜像命令：

```shell
$ docker build --build-arg apt_source=tencent -t redis:latest .
```

- `--build-arg apt_source=tencent`: 指定使用 Tencent 源，否则为默认源
- `-t redis:latest`: 指定生成的镜像及标签
- `.`: 指定 Dockerfile 文件路径为当前路径



----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))

