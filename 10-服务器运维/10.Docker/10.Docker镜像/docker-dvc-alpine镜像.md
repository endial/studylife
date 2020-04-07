# 简介



Git仓库地址：https://github.com/endial/docker-dvc-alpine

具体使用文档可参照[仓库说明文档](https://github.com/endial/docker-dvc-alpine/blob/master/README.md)。



## Dockerfile文件

默认Dockerfile文件如下：

```dockerfile
FROM endial/base-alpine:v3.11

MAINTAINER Endial Fang ( endial@126.com )

COPY entrypoint.sh /

VOLUME ["/srv/www", "/srv/cert", "/srv/data", "/srv/conf", "/var/log", "/var/run", "/etc/letsencrypt" ]

ENTRYPOINT ["/entrypoint.sh"]

CMD []
```





----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))

