# 简介

为Docker容器增加端口，主要有两类：

- 为运行中的容器增加端口
- 修改Dockerfile，重新生成镜像（这里不讨论）



## 为运行中的容器增加端口



### 使用iptables端口映射

> docker的端口映射并不是在docker技术中实现的，而是通过宿主机的iptables来实现。通过控制网桥来做端口映射，类似路由器中设置路由端口映射。



#### 端口映射查看

比如我们有一个容器的80端口映射到主机的8080端口，先查看iptables到底设置了什么规则：

```shell
sudo iptables -t nat -vnL
```

在结果中有一条：

```shell
Chain DOCKER
target     prot opt source               destination
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:172.17.0.3:80
```

我们可以看到docker创建了一个名为DOKCER的自定义的链条Chain。而我开放80端口的容器的ip是172.17.0.3。



也可以通过inspect命令查看容器ip:

```shell
docker inspect <Container Name or ID> | grep IPAddress
```



#### 为容器增加端口映射

我们想再增加一个端口映射，比如`8081->81`，就在这个链条是再加一条规则：

```shell
sudo iptables -t nat -A  DOCKER -p tcp --dport 8081 -j DNAT --to-destination 172.17.0.3:81
```



如果加错了或者想修改，可以先查看规则对应的行号，删除后重新添加：

```shell
# 查看规则对应的行号
sudo iptables -t nat -vnL DOCKER --line-number

# 删除行号对应的规则，如第三行的规则
sudo iptables -t nat -D DOCKER 3
```



### 修改配置文件

Linux上容器都是存储在目录`/var/lib/docker/containers``中，每个容器对应一个HASH ID。例如修改一下容器：

```shell
/var/lib/docker/containers/797f3d0cb82aec7d1c355c7461b5bc5a050c1c0cbbe5d813ede0edad061e6632
```



容器的配置文件`/var/lib/docker/containers/[containerId]`目录下，需要修改`hostconfig.json`和`config.v2.json`文件。



修改`hostconfig.json`，找到`PortBindings`节点并增加对应信息，如：

```
"PortBindings": {
	"80/tcp": {
		{
			"HostIp":"",
			"HostPort":"80"
		}
	}
},
```

修改为：

```
"PortBindings": {
	"80/tcp": {
		{
			"HostIp":"",
			"HostPort":"8080"
		}
	},
	"81/tcp": {
		{
			"HostIp":"",
			"HostPort":"8081"
		}
	}
},
```

> 注意元素之间的`,`分割。



修改`config.v2.json`，找到`ExposedPorts`节点：

```
"ExposedPorts": {
	"80/tcp":{}
}
```

修改为：

```
"ExposedPorts": {
	"80/tcp":{},
	"81/tcp":{}
}
```

> 注意元素之间的`,`分割。



保存，并重启启动容器。可以使用inspect查看端口信息：

```
docker inspect <Container Name or ID>
```





## 为容器重新生成镜像

针对动态增加端口的容器，可以提交一个运行中的容器为镜像：

```shell
docker commit containerid heropoo/example
```

则新的镜像默认具备80及81两个端口。



运行`heropoo/example`镜像并添加8081映射容器81端口：

```shell
docker run -d -p 8080:80 -p 8081:81  heropoo/example /bin/sh
```





## 参考

- https://www.mscto.com/docker/25252.html 
- https://juejin.im/post/5ce62beff265da1b897aa7b1



----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))
