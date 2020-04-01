# 简述

当前文档为Docker使用过程中可能遇到的问题的对应解决方案。



### 无法打开主机目录

现象：

> 挂载主机目录，访问出现`**Can not open directory.:Permission denied**`



解决方案：在挂载目录后多加一个`--privileged=true`参数。如

```shell
docker run -it -v  /hostDataVolume:/containerDataVolume  --privileged=true centos
```



### Firefox取消请求

现象：

> FirFox浏览器时，弹出以下提示：
> “此地址使用了一个通常用于网络浏览以外的端口。出于安全原因，Firefox 取消了该请求。”。



解决方案：

- 在Firefox地址栏输入`about:config` ,
- 然后在右键新建一个字符串键 `network.security.ports.banned.override` ,
- 将需访问网站的端口号添加到,值就是那个端口号即可,如`7080`
- 如有多个,就半角逗号隔开,例：`7080,6666,8888`。

在能保证安全的前提下,还简化成这样写`0-65535` ,这样可以浏览任意端口的网站了。


----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))
