# Redis

![Redis Logo](img/redis-logo_1200x500.jpg)



## 简介

REmote DIctionary Server(Redis) 是一个由Salvatore Sanfilippo写的key-value存储系统。

Redis是一个开源的使用ANSI C语言编写、遵守BSD协议、支持网络、可基于内存亦可持久化的日志型、Key-Value数据库，并提供多种语言的API。

它通常被称为数据结构服务器，因为值（value）可以是 字符串(String), 哈希(Hash), 列表(list), 集合(sets) 和 有序集合(sorted sets)等类型。



### Redis 优势

- 性能极高 – Redis能读的速度是110000次/s,写的速度是81000次/s 。
- 丰富的数据类型 – Redis支持二进制案例的 Strings, Lists, Hashes, Sets 及 Ordered Sets 数据类型操作。
- 原子 – Redis的所有操作都是原子性的，意思就是要么成功执行要么失败完全不执行。单个操作是原子性的。多个操作也支持事务，即原子性，通过MULTI和EXEC指令包起来。
- 丰富的特性 – Redis还支持 publish/subscribe, 通知, key 过期等等特性。
- 数据的持久化 – 可以将内存中的数据保存在磁盘中，重启的时候可以再次加载进行使用。



### Redis在Java Web中的应用

为什么用Redis？一个字，快！传统的关系型数据库如 Mysql 等已经不能适用所有的场景了，比如在高并发，访问流量高峰等情况时，数据库很容易崩了。Redis 运行在内存，能起到一个缓冲作用，由于内存的读写速度远快于硬盘，因此 Redis 在性能上比其他基于硬盘存储的数据库有明显的优势。同时除了快之外，还可应用于集群的自动容灾切换以及数据的读写分离，减轻高并发的压力。

- 存储 **缓存** 用的数据
- 需要高速读/写的场合**使用它快速读/写**



## 文档列表

- [Redis安装与基本操作-TODO](./Redis安装与基本操作.md)
- [Redis主从与哨兵模式集群-TODO](Redis主从与哨兵模式集群.md)



## Docker化应用

使用Docker镜像部署Redis，将更快速、简介；针对Redis的Docker化应用，参见[相应文档](../../10-服务器运维/10.Docker/README.md)。

针对使用过程中遇到的问题及解决方案，参见[问题解决文档](./Redis问题及解决.md)。



## 参考

- [Redis中文官方网站](http://www.redis.cn)
- [Redis官方网站](http://www.redis.io)
- [Redis菜鸟教程](https://www.runoob.com/redis/redis-tutorial.html)



----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))

