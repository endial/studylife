[TOC]

# 说明

本文主要是针对`OSX`使用过程中的针对个性化配置的日常记录，一个配置好的系统，总能加快个人工作效率，希望对你也有参考作用。



## 触发角配置

使用`系统偏好设置-》调度中心-》触发角`配置屏幕角触发：

- 左上角：调度中心
- 左下角：启动台
- 右上角：桌面
- 右下角：启动屏幕保护程序



## 更换文件夹图标

- 更换图标：
使用`预览`APP打开图片，并使用快捷键`CMD + C`拷贝图片；在需要更换图标的文件夹上右键单击，调出右键菜单，并选择`显示简介`；在弹出的简介界面中，左键单击左上角的图标，待出现图标选中轮廓后，使用快捷键`CMD + V`黏贴刚刚拷贝的图片内容。可以发现，文件夹图标已经更换为个性化图标。


- 恢复原图标：
在需要恢复默认图标的文件夹上右键单击，调出右键菜单，并选择`显示简介`；在弹出的简介界面中，左键单击左上角的图标，待出现选中框后，按`Delete`删除个性化图标，删除后，文件夹图标恢复为默认值。



## RamDisk配置

虽然SSD速度比较快，但考虑到毕竟开发过程中会经常牵涉到大量的编译操作，众多的临时文件反复读写还是会影响磁盘寿命；同时，将部分软件的缓存文件放置在内存中，也会提升软件性能，因此，为系统默认配置RamDisk。

具体配置文件及脚本，可参照[osx系统RamDisk配置](./RamDisk/osx系统RamDisk配置.md)文件中的步骤进行。

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
