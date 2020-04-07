# 简介

Alpine Linux是一个完整的操作系统，像其他操作系统一样，可以将Alpine安装到本地硬盘中。

Alpine Linux 网站首页注明“Small！Simple！Secure！Alpine Linux is a security-oriented, lightweight Linux distribution based on musl libc and busybox.”概括了以下特点：

- **小巧：**基于Musl libc和busybox，和busybox一样小巧，最小的Docker镜像只有5MB；
- **安全**：面向安全的轻量发行版；
- **简单**：提供APK包管理工具，软件的搜索、安装、删除、升级都非常方便。
- 适合**容器使用**：由于小巧、功能完备，非常适合作为容器的基础镜像。



Git仓库地址：https://github.com/endial/docker-base-alpine



## 差异介绍

当前镜像跟随官方主要镜像版本进行不定期更新，与官方镜像差异主要为使用的源不同。为了提升在国内使用时的软件包下载速度，系统默认修改使用中科大源。

具体使用文档可参照[仓库说明文档](https://github.com/endial/docker-base-alpine/README.md)。



## Dockerfile文件

默认Dockerfile文件如下：

```dockerfile
FROM alpine:3.11

MAINTAINER Endial Fang ( endial@126.com )

RUN echo "http://mirrors.ustc.edu.cn/alpine/v3.11/main" > /etc/apk/repositories \
  && echo "http://mirrors.ustc.edu.cn/alpine/v3.11/community" >> /etc/apk/repositories

CMD []
```



如果需要使用官方源，可使用以下Dockerfile：

```dockerfile
FROM alpine:3.11

MAINTAINER Endial Fang ( endial@126.com )

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.11/main" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/v3.11/community" >> /etc/apk/repositories

CMD []
```





----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))

