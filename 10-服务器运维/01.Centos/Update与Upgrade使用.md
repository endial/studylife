# 简述

```shell
update

If run without any packages, update will update every currently installed package. If one
or more packages or package globs are specified, Yum will only update the listed packages.
While updating packages, yum will ensure that all dependencies are satisfied. (See Specify‐
ing package names for more information) If the packages or globs specified match to packages
which are not currently installed then update will not install them. update operates on
groups, files, provides and filelists just like the "install" command.

If the main obsoletes configure option is true (default) or the --obsoletes flag is present
yum will include package obsoletes in its calculations - this makes it better for dis‐
tro-version changes, for example: upgrading from somelinux 8.0 to somelinux 9.

Note that "update" works on installed packages first, and only if there are no matches does
it look for available packages. The difference is most noticeable when you do "update
foo-1-2" which will act exactly as "update foo" if foo-1-2 is installed. You can use the
"update-to" if you'd prefer that nothing happen in the above case.

upgrade

Is the same as the update command with the --obsoletes flag set. See update for more
details.
```



从帮助信息可以看到，**`upgrade` 与附带 `--obsoletes` 的选项时的 `update` 是一样的**

然而，`update` 即使不附带 `--obsoletes` 选项时，默认的配置中将其设置为了 `true` （开启），在 `/etc/yum.conf` 文件中可以查看到默认的配置信息：

```shell
[main]
cachedir=/var/cache/yum/$basearch/$releasever
keepcache=0
debuglevel=2
logfile=/var/log/yum.log
exactarch=1
obsoletes=1
gpgcheck=1
plugins=1
installonly_limit=5
bugtracker_url=http://bugs.centos.org/set_project.php?project_id=23&ref=http://bugs.centos.org/bug_report_page.php?category=yum
distroverpkg=centos-release
```



所以，只能说默认情况下没有区别，而使用 `update` 则更为灵活。



## 生产环境

**生产环境对软件版本和内核版本要求非常精确，别没事有事随便的在CentOS上进行yum upgrade或update操作！**



## 开发环境

### 更新软件包及内核

```shell
yum -y update
yum -y upgrade
```



### 更新软件包，不更新内核

```shell
yum -y update --exclude=kernel* 
```



### 回滚更新

```shell
yum history undo
```



----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com) ([项目地址](https://github.com/endial/studylife.git))
