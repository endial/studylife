# 简介

Dockfile 是一种被 Docker 程序解释的脚本，Dockerfile 由一条一条的指令组成，每条指令对应 Linux 下面的一条命令。Docker 程序将这些 Dockerfile 指令翻译真正的 Linux 命令。Dockerfile 有自己书写格式和支持的命令，Docker 程序解决这些命令间的依赖关系，类似于 Makefile。Docker 程序将读取 Dockerfile，根据指令生成定制的 image。相比 image 这种黑盒子，Dockerfile 这种显而易见的脚本更容易被使用者接受，它明确的表明 image 是怎么产生的。有了 Dockerfile，当我们需要定制自己额外的需求时，只需在 Dockerfile 上添加或者修改指令，重新生成 image 即可，省去了敲命令的麻烦。

Dockerfile 语法由两部分构成，**注释** 和 **命令+参数**：

```dockerfile
# Line blocks used for commenting
command argument argument ..
```



Dockerfile 样例：

```dockerfile
# 第一行必须指定继承的基础镜像
FROM ubutu

# 维护者信息
MAINTAINER docker_user docker_user@mail.com

# 镜像的操作指令
RUN apt-get update && apt-get install -y ngnix 
RUN echo "\ndaemon off;">>/etc/ngnix/nignix.conf

# 容器启动时执行指令
ENTRYPOINT ["/usr/sbin/ngnix"]
```

> **约定**：
>
> - 以尖括号（`<`,`>`）定义的内容为参数，需要根据实际情况修改
> - 以方括号（`[`,`]`）为非必须的可选内容



## Dockerfile基础

虽然 Dockerfile 并不区分大小写，但还是约定指令使用大写。



### 构建

Docker 构建一个镜像，需要:

1. Dockerfile 文件
2. 构建所需的上下文

```
$ docker build .
```

这条命令中，Docker CLI 会：

1. 把当前目录及子目录当做上下文传递给 Docker 服务
2. 从当前目录(**不包括子目录**)中找到 Dockerfile
3. 检查 Dockerfile 的语法
4. **依次**执行 Dockerfile 中的指令，根据指令生成中间过渡镜像(存储在本地，为之后的指令或构建作缓存)

当然也可以用远程 git 仓库来代替本地路径，Docker 服务会把整个 git 仓库(包括git子模块)当做上下文，在仓库的根目录中寻找 Dockerfile。

> **注意**：为了加快构建速度，减少传递给 Docker 服务的文件数量，最好将 Dockerfile 放在单独的空目录中。如果目录中含有大量文件，可以使用 **.dockerignore** 来忽略构建时用不到的文件。



另一个例子：

```
$ docker build --no-cache=true -f /path/to/Dockerfile -t some_tag -t image_name:image_version /path/to/build
```

- `--no-cache`：不使用缓存，每条指令都重新生成镜像(速度会很慢)
- `-f`：明确指定 Dockerfile
- `-t`：给生成的镜像打上标签



如果以`docker build - < somefile`这种方式来构建镜像的，则没有上下文，`ADD`只能使用远程文件 URL 而`COPY`不能使用。如果以`docker build - < archive.tar.gz`，则会在压缩包的根目录中寻找 Dockerfile，压缩包的根目录当做上下文。



###  寻找缓存的逻辑

Docker [寻找缓存的逻辑](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#build-cache)其实就是树型结构根据 Dockerfile 指令遍历子节点的过程。下图可以说明这个逻辑。

```bash
     FROM base_image:version       Dockerfile:
           +----------+            FROM base_image:version
           |base image|            RUN cmd1  --> use cache because we found base image
           +-----X----+            RUN cmd11 --> use cache because we found cmd1
                / \
               /   \
       RUN cmd1     RUN cmd2       Dockerfile:
       +------+     +------+       FROM base_image:version
       |image1|     |image2|       RUN cmd2  --> use cache because we found base image
       +---X--+     +------+       RUN cmd21 --> not use cache because there's no child node
          / \                                    running cmd21, so we build a new image here
         /   \
RUN cmd11     RUN cmd12
+-------+     +-------+
|image11|     |image12|
+-------+     +-------+
```

大部分指令可以根据上述逻辑去寻找缓存，除了`ADD`和`COPY`。

这两个指令会复制文件内容到镜像内，除了指令相同以外，Docker 还会检查**每个文件内容**校验和(不包括最后修改时间和最后访问时间)，如果校验和不一致，则不会使用缓存。

> **注意**：除了这两个命令，Docker 并不会去检查容器内的文件内容，比如`RUN apt-get -y update`，每次执行时文件可能都不一样，但是 Docker 认为命令一致，会继续使用缓存。这样一来，以后构建时都不会再重新运行`apt-get -y update`。

如果 Docker 没有找到当前指令的缓存，则会构建一个新的镜像，并且之后的所有指令都不会再去寻找缓存。



### .dockerignore

在 Docker 构建镜像的第一步，Docker CLI 会先在上下文目录中寻找`.dockerignore`文件，根据`.dockerignore`文件排除上下文目录中的部分文件和目录，,然后把剩下的文件和目录传递给 Docker 服务。
`.dockerignore`语法同`.gitignore`，具体可以参考[官方文档](https://docs.docker.com/engine/reference/builder/#dockerignore-file)。



### 注释

以`#`开头的是注释，行内的`#`都被当做参数，并且不支持续行。



### 解析指令

解析指令也以`#`开头，形式如下：

```
# directive=value1
# directive=value2

FROM ImageName
```

解析指令是可选的，虽然不区分大小写，但还是约定使用小写。

解析指令会影响到 Dockerfile 的解析逻辑，并且不会生成图层，也不会在构建时显示。解析指令只能出现在 Dockerfile 头部，并且一条解析指令只能出现一次。如果碰到注释、Dockerfile 指令或空行，接下来出现的解析指令都无效，被当做注释处理。

解析指令不支持续行。

根据文档当前只有一个解析指令：`escape` 。escape 用来设置转义或续行字符，这在Windows中很有用：

```dockerfile
COPY testfile.txt c:\\
RUN dir c:\
```

会被 Docker 解析成: `COPY teestfile.txt c:\RUN dir c:`，无法正常使用。下面的例子就可以正常执行：

```dockerfile
# escape=`
COPY testfile.txt c:\
RUN dir c:\
```



### 环境变量

在 Dockerfile 中，使用`env`指令来定义环境变量。环境变量有两种形式：`$variable_name`和`${variable_name}`，推荐使用后者，因为：

- 可以复合值，如`${foo}_bar`，前者就无法做到
- 支持部分 bash 语法，下面例子中`word`除了字符串外也支持环境变量，进行递归替换:
  - `${variable:-word}`：如果`variable`不存在，则使用`word`
  - `${varialbe:+word}`：如果`variable`存在，则使用`word`，如果`variable`不存在，则使用空字符串



定义的变量支持这些指令：`ADD`，`COPY`，`ENV`，`EXPOSE`，`LABEL`，`USER`，`WORKDIR`，`VOLUME`，`STOPSIGNAL`和1.4版本之后的`ONBUILD`



**注意**：在整个指令行中只使用一个值，参考下面这个例子：

```
ENV abc=hello
ENV abc=bye def=$abc
ENV ghi=$abc
```

最后 abc=bye, def=hello, ghi=bye



## Dockerfile语法



### FROM

FROM 指令指定一个基础镜像，基础镜像可以为任意合理存在的 image 镜像。如果基础镜像没有被发现，Docker 将试图从 Docker image index 来查找该镜像。

FROM 指令必须是 Dockerfile 的首个非注释命令。

如果同一个 Dockerfile 创建多个镜像时，可使用多个 FROM 指令（每个镜像一次）。

如果没有指定 tag ，latest 将会被指定为要使用的基础镜像版本。

```dockerfile
# Usage: FROM [image name]
# Usage: FROM [image name]<:tag>
# Usage: FROM [image name]<@digest>
FROM ubuntu 
```

> **注**：`tag`和`digest`是可选的，如果不提供则使用`latest`。



### RUN

RUN 指令将在当前 image 中执行任意合法命令并提交执行结果。

RUN 指令是 Dockerfile 执行命令的核心部分。命令执行提交后，就会自动执行 Dockerfile 中的下一个指令。

层级 RUN 指令和生成提交是符合 Docker 核心理念的做法。它允许像版本控制那样，在任意一个点，对 image 镜像进行定制化构建。每一条 RUN 命令都是在之前 commit 的层之上形成新的层。

RUN 指令缓存不会在下个命令执行时自动失效。比如 `RUN apt-get -y dist-upgrade` 的缓存就可能被用于下一个指令。`--no-cache` 标志可以被用于强制取消缓存使用。



两种常见格式：

```dockerfile
# Usage: RUN executable parameter1 parameter2 ...：shell格式
RUN apt-get -y update 

# Usage: RUN ["excutable", "param1", "param2" ...]：exec格式
RUN ["/bin/bash", "-C", "echo hello"]
```

> 备注：当命令比较长时，可以使用` \`换行



### ENV

ENV 指令用于为 Docker 容器设置环境变量。在后续的 Dockerfile 指令中可以直接使用，也可以固化在镜像里，在容器运行时仍然有效。

支持两种格式：

```dockerfile
# Usage: ENV key value1 value2 ...
#      将第一个空格之后的所有值都当做`key`的值，无法在一行内设定多个环境变量
ENV TZ "Asia/Shanghai"
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Usage: ENV <key>=<value> ...：推荐使用
#      设置多个环境变量，如果value中存在空格，需要使用转义或`""`括起来；可以使用`\`换行
ENV myName="John Doe" \
    myDog=Rex\ The\ Dog \
    myCat=fluffy
```

> **注意**：
>
> - 可以在容器运行时指定环境变量，替换镜像中的已有变量，`docker run --env <key>=<value>`
> - 使用`ENV`可能会对后续的 Dockerfile 指令造成影响，如果只需要对一条指令设置环境变量，可以使用这种方式：`RUN <key>=<value> command param ... `
> - ENV 设置的环境变量，可以使用 `docker inspect` 命令来查看。



### USER

USER 指令用来切换运行属主的身份。

Docker 默认是使用 root，但若不需要，建议切换使用者身分，毕竟 `root` 权限太大了，使用上有安全的风险。

使用 USER 指令指定运行容器时的用户名或 UID 后，后续的 RUN 也会使用指定用户。

```bash
# Usage: USER [UID or name]
USER 751
USER daemon
```

> 注：
>
> - 可以在之前创建所需要的用户，例如： RUN groupadd -r postgres && useradd -r -g postgres postgres 
> - 要临时获取管理员权限可以使用 gosu ，而不推荐 sudo 
> - 受影响的指令有：`RUN`、`CMD`、`ENTRYPOINT`



### WORKDIR

WORKDIR 指令用于为后续的 RUN 、 CMD 、 ENTRYPOINT、COPY 和 ADD 指令配置工作目录。

Docker 默认的工作目录是 `/`，只有 RUN 能执行 `cd` 命令切换目录，而且还只作用在当前的 RUN，也就是说每一个 RUN 都是独立进行的。如果想让其他指令在指定的目录下执行，就得靠 WORKDIR。WORKDIR 动作的目录改变是持久的，不用每个指令前都使用一次 WORKDIR。

可以使用多个 WORKDIR 指令，如果参数是相对路径，则会基于之前命令指定的路径进行偏移。例如:

```dockerfile
# Usage: WORKDIR /path/to/workdir or relative/path/to/workdir
WORKDIR /a 
WORKDIR b 
WORKDIR c 
RUN pwd 
# 最终路径为 /a/b/c 。
```



### ADD

ADD 指令将文件从上下文中将路径 `<src>` 复制添加到容器内部路径 `<dest>`。具体可参考 [ADD指令](https://docs.docker.com/engine/reference/builder/#add)。

- `<src>` 必须是相对于源文件夹的一个文件或目录，也可以是一个远程的 URL。可以使用模糊匹配（wildcards，类似shell的匹配）。

- `<dest>` 是目标容器中的绝对路径。

  

所有的新文件和文件夹都会创建 UID 和 GID。事实上如果 `<src>` 是一个远程文件 URL，那么目标文件的权限将会是600。

```dockerfile
# Usage: ADD [source directory or URL] [destination directory]
ADD /my_app_folder /my_app_folder 
```

> **注意**：
>
> - 如果文件是可识别的压缩格式，则 Docker 会帮忙解压缩
> - 必须是在上下文目录和子目录中，无法添加`../a.txt`这样的文件。
> - 如果`<src>`是个目录，则复制的是**目录下的所有内容，但不包括该目录**。
> - 如果`<dest>`不存在，指令会自动创建所有目录，包括子目录。
> - 可以是绝对路径，也可以是相对`WORKDIR`目录的相对路径。
> - 所有文件的 UID 和 GID 都是0。



### COPY

COPY 指令将文件从路径 `<src>` 复制添加到容器内部路径 `<dest>`。

- `<src>` 必须是相对于源文件夹的一个文件或目录，也可以是一个远程的URL。

- `<dest>` 是目标容器中的绝对路径。

  

所有的新文件和文件夹都会创建 UID 和 GID。

```dockerfile
# Usage: ADD [source directory or URL] [destination directory]
COPY /my_app_folder /my_app_folder 
```

> **注意**：
>
> - COPY 指令不支持自动解压缩操作。
> - 必须是在上下文目录和子目录中，无法添加`../a.txt`这样的文件。
> - 如果`<src>`是个目录，则复制的是**目录下的所有内容，但不包括该目录**。
> - 如果`<dest>`不存在，指令会自动创建所有目录，包括子目录。
> - 可以是绝对路径，也可以是相对`WORKDIR`目录的相对路径。
> - 所有文件的 UID 和 GID 都是0。



### VOLUME

VOLUME 指令创建一个可以从本地主机（宿主机）或其他容器挂载的挂载点，一般用来存放数据库和需要保持的数据等。

```dockerfile
# Usage: VOLUME ["/dir_1", "/dir_2" ..]
VOLUME ["/my_files", "/app_files"]

# Usage: VOLUME "/dir_1", "/dir_2" ..
VOLUME "/my_files" "/app_files"
```

> **注意**：
>
> - 挂载点可以为路径或者文件
> - 在容器运行的时候，Docker 会把镜像中的数据卷的内容复制到容器的数据卷中去。
> - 如果在接下来的 Dockerfile 指令中，修改了数据卷中的内容，则修改无效。



### EXPOSE

EXPOSE 指令为构建的镜像设置监听端口，使容器在运行时监听。

```dockerfile
# Usage: EXPOSE <port> <port> ...
EXPOSE 80 8080 443
```

`EXPOSE`指令并不会让容器监听 host 的端口，如果需要，需要在`docker run`时使用`-p`、`-P`参数来发布容器端口到 host 的某个端口上。



### CMD

CMD 指令是指定 Docker Image 运行成实例（Container）时要执行的命令或文件。这些默认值可以包括可执行文件，也可以省略可执行文件。当你使用 shell 或 exec 格式时， CMD 会自动执行这个命令。

支持三种格式：

```dockerfile
# Usage 1: CMD  ["executable", "Param1", "Param2", ...]：exec格式，推荐
CMD ["echo", "Hello docker!"]

# Usage 2: CMD executable "Param1", "Param2", ..：shell格式
CMD "echo" "Hello docker!"

# Usage 3: CMD ["Param1", "Param2", ...]：省略可执行文件的exec格式，这种写法使`CMD`中的参数当做`ENTRYPOINT`的默认参数，此时`ENTRYPOINT`也应该是exec格式
CMD ["-f", "/etc/nginx/nginx.conf", "-g", "daemon off;"]
```

> 注意：每个 Dockerfile 中只能有一个 CMD 指令。 当指定多个时，只有最后一个起效。



### ENTRYPOINT

ENTRYPOINT 指令是指定 Docker Image 运行成实例（Container）时要执行的命令或文件。

官方文档有两个例子：[Exec form ENTRYPOINT example](https://docs.docker.com/engine/reference/builder/#exec-form-entrypoint-example)和[Shell form ENTRYPOINT example](https://docs.docker.com/engine/reference/builder/#shell-form-entrypoint-example)。

支持两种格式：

- ENTRYPOINT ["executable", "param1", "param2"]： 使用exec执行，PID为1，推荐
- ENTRYPOINT command param1 param2：shell中执行，无法获取PID；无法接受Unix信号，即在`docker stop`时收不到`SIGTERM`信号；并且不可被 docker run 提供的参数覆盖。
  


```dockerfile
# Usage 1: ENTRYPOINT  ["executable", "Param1", "Param2", ...]
ENTRYPOINT ["nginx"]

# Usage 2: ENTRYPOINT executable "Param1", "Param2", ..
ENTRYPOINT "nginx" "-f" "/etc/nginx/nginx.conf" "-g" "daemon off;"
```

> **注意**：
>
> - 每个 Dockerfile 中只能有一个 ENTRYPOINT 指令；当指定多个时，只有最后一个起效。



### ONBUILD

ONBUILD 指令向镜像中添加一个触发器，当以该镜像为 base image 再次构建新的镜像时，会触发执行其中的指令。

ONBUILD 的作用就是让指令延迟執行，延迟到下一个使用 FROM 的 Dockerfile 在建立 image 时执行，只限延迟一次。

ONBUILD 的使用情景是在建立镜像时取得最新的源码 (搭配 RUN ) 与限定系统框架。

格式：

```dockerfile
# Usage: ONBUILD [INSTRUCTION]
ONBUILD ADD . /app/src
```



比如我们生成的镜像是用来部署 Python 代码的，但是因为有多个项目可能会复用该镜像。所以一个合适的方式是：

```dockerfile
[...]
# 在下一次以此镜像为base image的构建中，执行ADD . /app/src，将项目代码添加到新镜像中去
ONBUILD ADD . /app/src
# 并且build Python代码
ONBUILD RUN /usr/local/bin/python-build --dir /app/src
[...]
```

> **注意**：
>
> - `ONBUILD`只会继承给子节点的镜像，不会再继承给孙子节点。
> - `ONBUILD ONBUILD`或者`ONBUILD FROM`或者`ONBUILD MAINTAINER`是不允许的。



### ARG

ARG 指令定义的变量只在建立 image 时有效，指定了用户在`docker build --build-arg =`时可以使用的参数，建立完成后变量就失效消失。

格式：

```dockerfile
# Usage: ARG <name>[=<default value>]
ARG user
```

构建参数在定义的时候生效而不是在使用的时候。如下面第三行开始的 user 才是用户构建参数传递过来的 user：

```dockerfile
FROM busybox
USER ${user:-some_user}
ARG user
USER $user
```

后续的`ENV`指令会覆盖同名的构建参数，正常用法如下：

```dockerfile
FROM ubuntu
ARG CONT_IMG_VER
ENV CONT_IMG_VER ${CONT_IMG_VER:-v1.0.0}
RUN echo $CONT_IMG_VER
```

Docker 内置了一批构建参数，可以不用在 Dockerfile 中声明：`HTTP_PROXY`、 `http_proxy`、 `HTTPS_PROXY`、 `https_proxy`、 `FTP_PROXY`、 `ftp_proxy`、 `NO_PROXY`、 `no_proxy`

> **注意**：
>
> - ARG 是 Docker1.9 版本才新加入的指令。
> - 在**使用构建参数**(而不是在构建参数定义的时候)的指令中，如果构建参数的值发生了变化，会导致该指令发生变化，会重新寻找缓存。



### LABEL

LABEL 指令定义一个 image 标签并赋值，其值为变量的值。

```dockerfile
# Usage: <key>=<value> <key>=<value> <key>=<value> ...
LABEL Owner=$Name
```



如果 base image 中也有标签，则继承，如果是同名标签，则覆盖。为了减少图层数量，尽量将标签写在一个`LABEL`指令中去，如：

```dockerfile
LABEL multi.label1="value1" \
      multi.label2="value2" \
      other="value3"
```



### STOPSIGNAL

STOPSIGNAL 指令触发系统信号。格式：

```dockerfile
STOPSIGNAL signal
```



### 3.17 HEALTHCHECK

`HEALTHCHECK 指令增加自定义的心跳检测功能，多次使用只有最后一次有效。格式：

```dockerfile
# Usage: HEALTHCHECK [OPTION] CMD <command> ：通过在容器内运行command来检查心跳
HEALTHCHECK --interval=5m --timeout=3s \
    CMD curl -f http://localhost/ || exit 1
    
# Usage: HEALTHCHECK NONE ：取消从base image继承来的心跳检测
HEALTHCHECK NONE
```

可选的`OPTION`：

- `--interval=DURATION`：检测间隔，默认30秒
- `--timeout=DURATION`：命令超时时间，默认30秒
- `--retries=N`：连续N次失败后标记为不健康，默认3次

`<command>`可以是 shell 脚本，也可以是 exec 格式的 json 数组。Docker 以`<command>`的退出状态码来区分容器是否健康，这一点同 shell 一致：

- 0：命令返回成功，容器健康
- 1：命令返回失败，容器不健康
- 2：保留状态码，不要使用

举例：每5分钟检测本地网页是否可访问，超时设为3秒：

```
HEALTHCHECK --interval=5m --timeout=3s \
    CMD curl -f http://localhost/ || exit 1
```

可以使用`docker inspect`命令来查看健康状态。

> **注意**：Docker版本1.12



### SHELL

SHELL 指令更改后续的 Dockerfile 指令中所使用的 shell。默认的 shell 是`["bin/sh", "-c"]`。可多次使用，每次都只改变后续指令。格式：

```dockerfile
# Usage: SHELL <command> [<"Parameters">]
SHELL ["executable", "parameters"]
```

> **注意**：Docker版本1.12



### MAINTAINER(已弃用)

MAINTAINER 指令指定维护者的信息，并应该放在 FROM 的后面。

```dockerfile
# Usage: MAINTAINER [name] <mail>
MAINTAINER authors-name <authors-email>
```

> 该命令不是必须的





## Dockerfile语法进阶

- 容器轻量化。从镜像中产生的容器应该尽量轻量化，能在足够短的时间内停止、销毁、重新生成并替换原来的容器。
- 使用`.dockerignore`。在大部分情况下，Dockerfile 会和构建所需的文件放在同一个目录中，为了提高构建的性能，应该使用`.dockerignore`来过滤掉不需要的文件和目录。`.dockerignore`语法同`.gitignore`。
- 为了减少镜像的大小，减少依赖，**仅安装**需要的软件包。
- 一个容器只做一件事。解耦复杂的应用，分成多个容器，而不是所有东西都放在一个容器内运行。如一个 Python Web 应用，可能需要 Server、DB、Cache、MQ、Log 等几个容器。一个更加极端的说法：One process per container。
- 减少镜像的图层。不要多个`Label`、`ENV`等标签。
- 对续行的参数按照字母表排序，特别是使用`apt-get install -y`安装包的时候。
- 使用构建缓存。如果不想使用缓存，可以在构建的时候使用参数`--no-cache=true`来强制重新生成中间镜像。



### Shell与Exec格式指令

大部分同时有shell格式和exec格式的指令，他们的区别在于:

- shell 格式的是在某个 shell 中(默认为`/bin/sh -c`)运行可执行文件，exec 格式的是直接执行可执行文件。如果exec格式的要在某个 shell 中执行，要这么写：`["/bin/bash", "-c", "echo hello"]`。shell 可以使用`SHELL`指令来更改。
- shell 格式支持使用转义符(默认为`\\`)来换行。
- exec 格式被解析为 json 数组，所以使用双引号`"`而不是单引号`'`。
- exec 格式因为不在 shell 中执行，不会进行变量替换，而 shell 格式的可以。如`RUN ["echo", "$HOME"]`不会将`$HOME`展开，如果需要展开变量，可以这样使用：`RUN ["sh", "-c", "echo $HOME"]`



### CMD与ENTRYPOINT

`CMD`和`ENTRYPOINT`至少得使用一个。`ENTRYPOINT`应该被当做 Docker 的可执行程序，`CMD`应该被当做`ENTRYPOINT`的默认参数。

`docker run <image> <arg1> <arg2> ...`会把之后的参数传递给`ENTRYPOINT`，覆盖`CMD`指定的参数。可以用`docker run --entrypoint`来重置默认的`ENTRYPOINT`。

关于`ENTRYPOINT`和`CMD`的交互，用一个官方表格可以说明：

|                                | **No ENTRYPOINT**   | **ENTRYPOINT exec_entry p1_entry** | **ENTRYPOINT ["exec_entry", "p1_entry"]**      |
| ------------------------------ | ------------------- | ---------------------------------- | ---------------------------------------------- |
| **No CMD**                     | error, not allowed  | /bin/sh -c exec_entry p1_entry     | exec_entry p1_entry                            |
| **CMD ["exec_cmd", "p1_cmd"]** | exec_cmd p1_cmd     | /bin/sh -c exec_entry p1_entry     | exec_entry p1_entry exec_cmd p1_cmd            |
| **CMD ["p1_cmd", "p2_cmd"]**   | p1_cmd p2_cmd       | /bin/sh -c exec_entry p1_entry     | exec_entry p1_entry p1_cmd p2_cmd              |
| **CMD exec_cmd p1_cmd**        | CMD exec_cmd p1_cmd | /bin/sh -c exec_entry p1_entry     | exec_entry p1_entry /bin/sh -c exec_cmd p1_cmd |



如果两个同时使用，请确定确定他们的含义没有错误。此时，`ENTRYPOINT`指令的主要用途是把容器当做命令来用，`CMD`指令来指定默认参数。可以自己写脚本来当做`ENTRYPOINT`。

如果用户不清楚镜像的 ENTRYPOINT 是什么，不要将 CMD 和`ENTRYPOINT`配合使用，不要使用`CMD ["param1", "param2"]`。

- CMD 和 ENTRYPOINT 都能用来指定开始运行的程序，而且这两个命令都有两种不用的语法：

```dockerfile
CMD ls -l
```

or

```dockerfile
CMD ["ls", "-l"]
```

对于第一种语法，Docker 会自动加入 "/bin/sh –c" 到命令中，这样就有可能导致意想不到的行为。为了避免这种行为，我们推荐所有的 CMD 和 ENTRYPOINT 都应该使用第二种语法。



### FROM

尽可能的使用官方镜像，推荐使用 Debian Image。如果追求镜像的大小，可以考虑 alpine 或 scratch。



### LABEL

在一个`Label`指令内添加多个标签。如：

```dockerfile
LABEL vendor=ACME\ Incorporated \
      com.example.is-beta= \
      com.example.is-production="" \
      com.example.version="0.0.1-beta" \
      com.example.release-date="2015-02-12"
```



### RUN

为了增加 Dockerfile 的可读性和可维护性，将复杂的`RUN`指令分行写，不要全部写在一行。

- APT-GET
  - 避免使用`apt-get upgrade`或`dist-upgrade`，这会更新大量不必要的系统包，增加了镜像大小。如果需要更新包，简单的使用`RUN apt-get update && apt-get install -y <package>`就好。
  - 如果<package>很多的话，分行并按字母表排序。
  - `apt-get update`和`apt-get install -y <package>`要在一个`RUN`指令内，如果在多个`RUN`指令内，Docker 会使用缓存。
  - Debian 和 Ubuntu 的官方镜像会自动执行`apt-get clean`语句。如果是其他镜像，手动执行该指令，或删除`/var/lib/apt/lists`下的文件。

- 管道

带管道的命令，其返回值是最后一条命令的返回值。所以如果管道前的命令出错而管道后的指令正常执行，则 Docker 不会认为这条指令有问题。如果需要所有的管道命令都正常执行，可以增加`set -o pipefail`，如：

```
RUN set -o pipefail && wget -O - https://some.site | wc -l > /number
```

部分 shell 不支持`set -o pipefail`，所以需要指定 shell。如：

```
RUN ["/bin/bash", "-c", "set -o pipefail && wget -O - https://some.site | wc -l > /number"]
```



### EXPOSE

如果你的镜像是个服务，如 Apache 这样的，使用正常的、通用的端口，如80端口。



### ENV

可以修改 PATH 环境变量来优先使用自己的可执行文件。可以当做变量来使用，控制 Dockerfile 中的其他指令，使Dockerfile 更易维护。如：

```dockerfile
ENV PG_MAJOR 9.3
ENV PG_VERSION 9.3.4
RUN curl -SL http://example.com/postgres-$PG_VERSION.tar.xz | tar -xJC /usr/src/postgress && …
ENV PATH /usr/local/postgres-$PG_MAJOR/bin:$PATH
```



### ADD和COPY

这两个指令类似，但如果只是复制文件到镜像内，仍然推荐使用`COPY`，因为`COPY`在功能上更单一，而`ADD`指令有更多的特性(如远程文件、自动解压等)。

`ADD`指令使用的最好时机是想镜像内添加压缩包，`ADD`会自动解压。**强烈**不建议使用`ADD`来添加远程文件。如果确实需要远程文件，应该使用`RUN wget`或`RUN curl`。

使用`ADD`或`COPY`远程文件的，会赋予文件600权限，并且HTTP `Last-Modified`时间就是文件的最后修改时间。最后修改时间被改变，Docker 不会认为文件被改变，Docker 只会检查文件内容。



### VOLUME

**强烈**建议使用该指令为用户数据创建数据卷，如数据的存储位置、配置文件的存储位置或用户自己创建的文件/目录等。



### USER

如果镜像的服务不用授权就能使用，那应该新增用户和组，以新用户来执行，如：

```dockerfile
RUN groupadd -r postgres && useradd -r -g postgres postgres
```

需要注意的是，UID/GID 是顺着镜像中已存在的 UID/GID 创建的，如果对这个有严格要求，应该自己显式定义 UID/GID。

不要在镜像内安装或使用`sudo`，如果需要类似的功能，可以使用`gosu`。

也不要来来回回的切换用户，这样会增加图层层数。



### WORKDIR

只使用绝对路径。切换工作目录只使用`WORKDIR`而不是`RUN cd ... && do-something`。



### ONBUILD

在运行`docker build`命令时，在执行任何指令前，先执行父 Dockerfile 中定义的`ONBUILD`指令。
在打标签时应该添加这些信息，如：`ruby:1.9-onbuild`。

ONBUILD 指令谨慎使用`COPY`和`ADD`，因为有可能在子构建中并不存在对应的文件或目录。



### 尽量合并命令

Dockerfile 中的每一个命令都会创建一个新的 layer，而一个容器能够拥有的最多 layer 数是有限制的。所以尽量将逻辑上连贯的命令合并可以减少 layer 的层数，合并命令的方法可以包括将多个可以合并的命令（EXPOSE， ENV，VOLUME，COPY）合并，这也可以加快编译速度。比如：

```dockerfile
EXPOSE 80
EXPOSE 8080
CMD cd /tmp
CMD ls
```

合并为：

```dockerfile
EXPOSE 80 8080
CMD cd /tmp && ls
```





## 创建自己的镜像

### 通过工具生成基础OS

通过`debootstrap`类似的工具来生成一个基础的 OS，然后导入到 Docker 中：

```bash
$ sudo debootstrap raring raring > /dev/null
$ sudo tar -C raring -c . | docker import - raring

a29c15f1bf7a

$ docker run raring cat /etc/lsb-release

DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=13.04
DISTRIB_CODENAME=raring
DISTRIB_DESCRIPTION="Ubuntu 13.04"
```



### 使用scratch镜像

从 scratch 镜像重新开始构建。scratch 是 docker 中最小的镜像。如：

```dockerfile
FROM scratch
ADD hello /
CMD ["/hello"]
```





## 参考

- https://www.jianshu.com/p/690844302df5
- https://www.jianshu.com/p/5f4b1ade9dfc
- https://github.com/qianlei90/Blog/issues/35

----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))
