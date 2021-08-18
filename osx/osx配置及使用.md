[TOC]

# 说明

本文主要是针对`OSX`使用过程中的针对个性化配置的日常记录，一个配置好的系统，总能加快个人工作效率，希望对你也有参考作用。



## 触发角配置

使用`系统偏好设置-》调度中心-》触发角`配置屏幕角触发：

- 左上角：调度中心
- 左下角：启动台
- 右上角：桌面
- 右下角：启动屏幕保护程序

更改`系统偏好设置-》安全性与隐私-》通用`中的有关启用密码选项，选中: 进入睡眠或开始屏幕保护程序`立即`要求输入密码



## 节能

### 关闭蓝牙唤醒

- 转到系统偏好设置
- 单击蓝牙
- 按高级
- 取消选中“允许蓝牙设备唤醒此计算机”旁边的框



### 关闭电源小睡

- 单击苹果菜单，然后选择系统偏好设置
- 选择节能器
- 取消选中“使用电池供电时启用小睡”旁边的框



### 关闭睡眠时通知

- 在“系统偏好设置”中，选择“通知”
- 单击左侧边栏顶部的请勿打扰
- 选中“显示器休眠时”旁边的框



## 更换文件夹图标

- 更换图标：
使用`预览`APP打开图片，并使用快捷键`CMD + C`拷贝图片；在需要更换图标的文件夹上右键单击，调出右键菜单，并选择`显示简介`；在弹出的简介界面中，左键单击左上角的图标，待出现图标选中轮廓后，使用快捷键`CMD + V`黏贴刚刚拷贝的图片内容。可以发现，文件夹图标已经更换为个性化图标。


- 恢复原图标：
在需要恢复默认图标的文件夹上右键单击，调出右键菜单，并选择`显示简介`；在弹出的简介界面中，左键单击左上角的图标，待出现选中框后，按`Delete`删除个性化图标，删除后，文件夹图标恢复为默认值。



## RamDisk配置

虽然 SSD 速度比较快，但考虑到毕竟开发过程中会经常牵涉到大量的编译操作，众多的临时文件反复读写还是会影响磁盘寿命；同时，将部分软件的缓存文件放置在内存中，也会提升软件性能，因此，为系统默认配置 RamDisk。

具体配置文件及脚本，可参照<[OSX系统RamDisk配置](./RamDisk/osx系统RamDisk配置.md)>文件中的步骤进行。

***当前版本中，Safari缓存如果移动至RamDisk，将无法写入，待解决***



## 使用config配置SSH

日常工作使用中，虽然可以在使用`SSH`时，直接指定所需要使用的证书文件，但毕竟比较繁琐。针对常用的目标，可以定义一组配置信息，放置在`~/.ssh/config`文件中，简化命令，提升效率。



### config书写说明

基本格式：

以下内容中使用`<>`括起的内容，需要根据实际情况修改。可以配置多组`Host`。

```
Host <hostname>
	HostName <DNS or IP Address>
	Port <Port Number, default 22>
	User <User Name to Login>
	IdentityFile <~/.ssh/id-file-name>
	IdentitiesOnly <是否只接受 SSH Key 认证>
	PreferredAuthentications <使用的认证类型，如 publickey 验证>
```



参数说明：

- Host：可以使用域名，或者简短的英文名，但需要在配置文件中唯一
- HostName：对应的主机名称、DNS或IP地址；如果`Host`为域名，该字段可以省略，以配置一组关联的服务器
- Port：使用的认证端口，默认为`22`；如果使用默认端口，该字段可以省略
- User：使用的用户名；如果省略该字段，需要在命令行中指定
- IdentityFile：秘钥文件的具体路径（指向私钥文件）
- IdentitiesOnly：是否只接受秘钥文件认证，根据服务器配置确定；该字段可以省略
- PreferredAuthentications：认证方式，默认为`publickey`



简化使用：

- 配置一组服务器(xxx.github.com)，且不指定用户名：

```
Host a.github.com b.github.com c.github.com
    IdentityFile ~/.ssh/file_name_rsa
    PreferredAuthentications publickey
```

- 配置简化名称，且指定用户名：

```
Host vpn
    HostName 192.168.100.10
    User root
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/file_name_rsa
    
Host git
    HostName 192.168.100.11
    User git
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/file_name_rsa
```



## OSX 常用命令



### 增加登录及注销执行脚本

- 查询当前自动执行的脚本

```
sudo defaults read com.apple.loginwindow LoginHook
sudo defaults read com.apple.loginwindow LogoutHook
```

- 增加用户登录时执行的脚本（必须可执行）

```
sudo defaults write com.apple.loginwindow LoginHook </Path/to/shell>
```

- 增加用户注销时执行的脚本（必须可执行）

```
sudo defaults write com.apple.loginwindow LogoutHook </Path/to/shell>
```

- 删除执行的脚本

```
sudo defaults delete com.apple.loginwindow LoginHook
sudo defaults delete com.apple.loginwindow LogoutHook
```



### 增加系统自启动应用及任务



## 重置系统管理控制器SMC

如果系统出现异常，可以尝试重置Mac的SMC。SMC管理各种硬件过程，包括电池的工作方式。虽然这是万不得已的方法，但它不会对Mac造成任何损害，Apple经常推荐它作为无法通过简单解决方案解决的问题的解决方案。

如何使用不可拆卸的电池在MacBooks上重置SMC：

- 关闭MacBook

- 关闭时，请按Shift + Control + Option（Alt）键

- 按住这些键的同时，按电源按钮（在带有Touch Bar的MacBook上，Touch ID按钮为电源按钮）

- 按住键和电源按钮十秒钟，然后松开它们

- 再次按电源按钮以启动Mac

  

如何使用可拆卸电池在MacBooks上重置SMC：

- 关闭您的Mac

- 取出电池

- 按住电源按钮（Touch ID按钮）5秒钟

- 重新安装电池

- 按电源按钮启动Mac



## 关闭 ReportCrash

### 关掉 ReportCrash

这个操作会停止 ReportCrash，立竿见影，机器立马冷静。而且开机后，不会再次发生这个问题。

```shell
launchctl unload -w /System/Library/LaunchAgents/com.apple.ReportCrash.plist
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.ReportCrash.Root.plist
```



### 重新启用 ReportCrash

这个操作用是后悔药。有些有洁癖的同学，可以通过它反悔。

```shell
launchctl load -w /System/Library/LaunchAgents/com.apple.ReportCrash.plist
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.ReportCrash.Root.plist
```



## 禁用`deleted`进程

`deleted`进程由 CacheDelete 启动，相应的启动程序列表在目录`/System/Library/CacheDelete`中，如果需要修改该目录文件，需要先禁用 SIP（System Integrity Protection）。



### 禁用SIP

如果需要禁用 SIP，需要先进入系统恢复模式。

- 重启系统
- 在系统启动时，按住 **Cmd + R** 键，直到出现加载进度条
- 在系统菜单启动终端： `Utilities > Terminal`
- 在终端中运行命令 `csrutil disable`，运行成功后可以看到 SIP 被禁用的提示
- 重启电脑



### 移除CacheDelete目录

使用正常用户账号登陆系统后，重新挂载系统目录为可写模式：

```shell
$ sudo mount -uw /
```

将 CacheDelete 目录移动到新位置：

```shell
$ sudo mv /System/Library/CacheDelete /System/Library/CacheDeleteBackup
```

重启电脑，重启后进入`活动监视器`查看 CPU 占用情况。此时，`deleted`的 CPU 占用应该降低，也不会周期性的激增。

> 注意：如果同时将 deleted 可执行文件移除或移动至其他位置，则系统可能启动异常。



## 禁用 Spotlight

Spotlight（OS X系统的搜索程序）会索引所有文件以进行快速搜索，但索引操作会占用较多的 CPU 和磁盘 IO，并会周期性的运行（系统的`mds_stores`进程）。

如果不需要使用 Spolight，可以考虑禁用该程序：

```shell
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
```

> 注意：该操作需要在禁用 SIP 之后才能完成

可以通过以下命令重新启用：

```shell
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
```



## 减少透明度

减少透明度可以有效降低`WindowServer`进程的 CPU 占用。

- 打开`系统偏好设置`
- 进入`辅助功能`->`显示`
- 选中`减少透明度`选项
