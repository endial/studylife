# 说明

作为一个 Macbook Pro 的老用户，在新年到来之际，狠心给自己买了个大礼物。因为之前使用较旧的系统，虽然可以使用系统自带的`迁移助理`进行配置和数据文件传输，但考虑到系统中残留的各种信息比较多，还是决定浪费一点点时间进行重新配置，本文主要为记载重新配置过程中，进行的各种文件安装及操作。针对系统使用过程中的个性化配置，可参照<[OSX配置及使用](./osx配置及使用.md)>设置说明文档。



## 基本环境配置

新 MAC 的基本配置信息：

- MacBook Pro 16-inch，2019
- OS：macOS Catalina 10.15.3
- CPU：2.3GHz 八核 Intel Core i9
- 内存：64 GB 2667MHz DDR4
- 磁盘：4TB SSD



考虑到开发过程中，经常需要使用`大小写敏感`的磁盘，这里对磁盘进行重新分区：

- Data：1.5TB，APFS
- Work：2.5TB，Mac OS Extended，Case-sensitive



#### 分区挂载路径配置

系统默认将磁盘挂载在 `/Volumes`目录中，如果需要挂载在其他位置，可以按一下方式操作（如挂载 Work 磁盘为 ~/Work):

使用`diskutil list`获取磁盘标识：

```shell
$ diskutil list
......
/dev/disk1 (synthesized):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      APFS Container Scheme -                      +250.0 GB   disk1
                                 Physical Store disk0s3
   1:                APFS Volume work                    91.2 GB    disk1s1
```



使用`diskutil info /dev/disk1`获取磁盘 UUID（如磁盘 /dev/disk1)：

```shell
$ diskutil info /dev/disk1
   Device Identifier:         disk1
   Device Node:               /dev/disk1
......
   Disk / Partition UUID:     F7B36E76-8FF3-4CB2-889E-9663C971933B
......
```

修改文件`/etc/fstab`设置开机自动挂载路径：

```shell
$ sudo vi /etc/fstab
# 增加类似如下内容(使用 UUID)
UUID=F7B36E76-8FF3-4CB2-889E-9663C971933B /Users/endial/work apfs rw
```




### 配置 RamDisk

虽然 SSD 速度比较快，但考虑到毕竟开发过程中会经常牵涉到大量的编译操作，众多的临时文件反复读写还是会影响磁盘寿命；同时，将部分软件的缓存文件放置在内存中，也会提升软件性能，因此，为系统默认配置 RamDisk。

具体配置文件及脚本，可参照<[osx系统RamDisk配置](./RamDisk/osx系统RamDisk配置.md)>文件中的步骤进行。

***当前版本中，Safari缓存如果移动至RamDisk，将无法写入，待解决***



### 个人`SSH`证书备份及恢复

恢复系统中个人证书，证书存放目录为`~/.ssh`,需要注意证书目录的权限为`711`；证书目录中：

- 个人私钥文件权限为600
- 个人公钥文件权限为644
- [使用`config`文件](./osx配置及使用.md#使用config配置SSH)，配置默认服务器所使用的证书文件



如果个人证书（主要是私钥文件）权限不正确，在使用`Git`克隆仓库时，会遇到类似如下的错误提示：

```
Load key "/Users/endial/.ssh/Endial_rsa_git": bad permissions
```



### 系统工具安装

系统工具主要针对使用频度较高或比较基础的应用软件，需要尽早安装：

- NTFS for Mac：为系统增加 NTFS 写入支持 
- Little Snitch：防火墙软件，用户后续软件破解或屏蔽网络登录 
- Sougo 输入法：搜狗中文输入法 
- 1Password：个人密码保存及管理工具
- Bartender：系统状态栏应用图标隐藏工具 



## 基本工具安装



### oh-my-zsh

Catalina 系统默认使用 ZSH，为了方便使用，安装`oh-my-zsh`配置脚本：

```
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```



修改文件`~/.zshrc`，配置个性化主题：

```
ZSH_THEME="robbyrussell"
```

也可以把主题设置成随机，随机到自己喜欢的主题，记下名字再修成那个主题。



重启`Terminal`或运行命令`source ~/.zshrc`使配置立即生效。



常用`~/.zshrc`配置：

```shell
plugins=(
	autojump
	zsh-syntax-highlighting
	zsh-autosuggestions
)

# 定义扩展名对应的默认打开方式
alias -s html=subl   # 在命令行直接输入后缀为 html 的文件名，会在 Sbulime Text 中打开
alias -s rb=subl     # 在命令行直接输入 ruby 文件，会在 Sublime Text 中打开
alias -s py=subl       # 在命令行直接输入 python 文件，会用 nano 中打开，以下类似
alias -s js=subl
alias -s c=subl
alias -s go=subl
alias -s java=subl
alias -s txt=subl
alias -s md=typora
alias -s db=navi	# 使用Navicat Premium打开Sqlite数据库文件
alias -s gz='tar -xzvf'
alias -s tgz='tar -xzvf'
alias -s zip='unzip'
alias -s bz2='tar -xjvf'

# 定义命令别名
alias cls='clear'
alias ll='ls -l'
alias la='ls -a'
alias vi='nano'
#alias javac="javac -J-Dfile.encoding=utf8"
alias grep="grep --color=auto"
#alias aria2="aria2c --conf-path="~/Documents/aria2.conf" -D"
alias typora="open -a typora" 	# 暂时不用，已将可执行文件连接至/usr/local/bin/typora
alias nn=nano
alias tree="tree -N"	# 解决中文乱码问题
alias navi="open -a \"Navicat Premium\""

alias proxyon="export http_proxy=http://127.0.0.1:1087; export https_proxy=http://127.0.0.1:1087"
alias proxyoff="unset http_proxy; unset https_proxy"

# 设置环境变量
export GOPATH="/Users/endial/Golang"
export GOPROXY=https://goproxy.cn,https://goproxy.io,direct
export GO111MODULE=auto
export PATH="${PATH}:~/Golang/bin"

PATH="${PATH}:~/Library/Android/sdk/platform-tools"
PATH="/usr/local/sbin:${PATH}"
export PATH

export ANDROID_HOME="~/Library/Android/sdk"
export ANDROID_SDK_ROOT="~/Library/Android/sdk"
export ANDROID_NDK_HOME="~/Library/Android/sdk/ndk-bundle"

export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
export DOCKER_VOLUME_BASE=/Volumes/RamDisk/Volumes

# fix bug for command 'find' always return 'no matches found: ...'
setopt no_nomatch
```



### brew

[Brew](http://brew.sh/) 是 Mac 下面的包管理工具，通过 Github 托管适合 Mac 的编译配置以及 Patch，可以方便的安装开发工具。

后续大部分基本工具使用`brew`安装，因此，先安装`homebrew`工具，安装命令可参考 [Homebrew官网](https://brew.sh/) 指导说明：

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

对于国内用户访问Github比较慢的问题，可以参照[使用国内源安装Brew](#使用国内源安装Brew)进行安装。



使用`brew`安装的包：

```
brew update
brew install tmux git subversion upx curl wget dos2unix autoconf automake cmake autojump brew install go protobuf protoc-gen-go tree telnet
brew install sshfs
```

- sshfs：用于远程文件系统挂载，需要搭配`osxfuse`，参见[`sshfs.md`](./docs/sshfs.md)
- tmux：终端分屏管理工具
- git：Git协议支持
- subversion：Subversion协议支持
- go：Golang编译器
- upx：可执行文件压缩器
- curl：利用URL规则的命令行下载工具
- wget：利用URL规则的命令行下载工具
- dos2unix：文档格式转换工具
- autoconf/automake/cmake：编译相关
- autojump：oh-my-zsh使用的自动跳转插件
- protobuf：Protobuf协议工具
- protoc-gen-go：针对Golang的Protobuf代码生成工具
- tree：目录树显示工具
- telnet：Telnet工具

  



#### brew 启动已安装的应用服务

针对已经安装的brew包，可以使用以下命令行方式启动后台服务（如 Redis）：

```
brew services start redis
```



### brew cask

[Brew cask](https://github.com/phinze/homebrew-cask) 是类似 Brew 的管理工具， 直接提供 dmg 级别的二进制包，（Brew 是不带源码，只有对应项目所在的 URL）。



使用`brew cask`安装的包：

```
brew cask install google-chrome iterm2 wechat qq baidunetdisk osxfuse neteasemusic keka alfred cheatsheet shadowsocksx-ng wireshark homebrew/cask-versions/microsoft-remote-desktop-beta  mplayerx vlc vlcstreamer smartgit folx typora poedit xld ichm postman sublime-text xscope go2shell docker
brew cask install cLion goland 
brew cask install android-file-transfer homebrew/cask-versions/adoptopenjdk8
```

- google-chrome：Chrome浏览器
- iterm2：好用的终端软件，完全可以替代系统的Terminal
- alfred：效率工具，必装，完全代替系统的Spotlight
- cheatsheet：效率工具，快捷键提示
- mplayerx：媒体播放工具
- vlc：媒体播放工具
- vlcstreamer：VLC推流工具
- shadowsocksx-ng：VPN科学上网工具
- wireshark：网络分析工具
- wechat：微信
- qq：QQ
- microsoft-remote-desktop-beta：远程桌面
- baidunetdisk：百度网盘
- osxfuse：OSX上远程文件系统挂载工具，需要搭配`sshfs`，参见[`sshfs.md`](./docs/sshfs.md)
- smartgit：Git图形化工具
- folx：下载工具
- typora：Markdown编辑器
- poedit：PO文件编辑器
- xld：音乐文件转换工具
- neteasemusic：网易云音乐
- ichm：HELP文件浏览工具
- keka：压缩工具
- postman：API调试
- sublime-text：Sublime Text文编编辑器
- xscope：屏幕测量工具
- go2shell：Finder中集成Shell快捷键
- CLion：C/C++ 开发IDE
- GoLand：Golang 开发IDE
- WebStorm：Nodejs 开发 IDE
- Android-file-transfer：Android系统文件传输工具
- homebrew/cask-versions/adoptopenjdk8: JDK 8.0



## 日常办公及常用软件

[TODO]

- jxplorer：LDAP管理工具，需要JDK环境支持，[官网下载](https://sourceforge.net/projects/jxplorer/)



## 专业开发软件安装



### MongoDB安装

因MongoDB软件已经宣布不再开源，因此，该软件已经无法直接使用`brew`进行`MongoDB`的安装，但可以使用`brew`安装该软件的社区版本：

```
brew tap mongodb/brew
brew install mongodb-community
```



## 软件配置及问题解决



### Wireshark 提示`Wireshark: Permission denied`

安装软件后，可能每次启动`Terminal`时，会出现如下的提示错误：

```
Wireshark: Permission denied
```



**问题原因：**

```
This is the case after installing "Add Wireshark to the system PATH" and seems to be a problem in the upstream package. After installation, these two files are not readable and cause the above error:
-rw-------  1 root  wheel  57 Nov 20 18:19 /etc/manpaths.d/Wireshark
-rw-------  1 root  wheel  43 Nov 20 18:19 /etc/paths.d/Wireshark
```



**解决方案：**

```
sudo chmod 644 /etc/manpaths.d/Wireshark /etc/paths.d/Wireshark
```



### ShadowsocksX-NG 闪退

安装`ShadowsocksX-NG`科学上网软件后，发现无法启动，出现软件闪退现象。



问题原因：**

问题出现原因在该软件的[版本描述](https://github.com/shadowsocks/ShadowsocksX-NG/releases)中有说明：

```
Known Issue:
#1185 Would crash in fresh installation. Work around: Make sure the folder ~/.ShadowsocksX-NG exists.
```



解决方案：**

```
mkdir ~/.ShadowsocksX-NG
```



### tree命令显示中文乱码

`brew`安装`tree`后，针对中文显示，会有乱码出现。



**解决方案：**

在`.zshrc`文件中增加相应配置：

```
alias tree="tree -N"
```



### Jetbrains 系列工具提示`Filesystem Case-Sensitivity Mismatch`

![case_mismatch_notification](img/case_mismatch_notification.png)



问题原因：**

在 Mac OSX 及 Wndows 系统中，Jetbrains 相关的 IDEs 默认使用大小写无关选项；如果项目所在磁盘分区为大小写敏感的，则会提示该问题。



**解决方案：**

在 IDEA 的`idea.properties`配置文件中增加有关选项；进入配置选项方式为相应 IDEA 的菜单`Help -> Edit Custom Properties`,如果配置文件不存在，按提示创建一个，并在最后增加如下内容：

```
idea.case.sensitive.fs=true
```



## 使用国内源安装Brew

### 使用中科大源安装

```bash
/usr/bin/ruby -e "$(curl -fsSL https://cdn.jsdelivr.net/gh/ineo6/homebrew-install/install)"
```

如果命令执行中卡在下面信息：

```bash
==> Tapping homebrew/core
Cloning into '/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core'...
```

请`Control + C`中断脚本执行如下命令：

```bash
cd "$(brew --repo)/Library/Taps/"
mkdir homebrew && cd homebrew
git clone git://mirrors.ustc.edu.cn/homebrew-core.git
```

**`cask` 同样也有安装失败或者卡住的问题，解决方法也是一样：**

```bash
cd "$(brew --repo)/Library/Taps/"
cd homebrew
git clone https://mirrors.ustc.edu.cn/homebrew-cask.git
```

成功执行之后继续执行前文的安装命令:

```bash
/usr/bin/ruby -e "$(curl -fsSL https://cdn.jsdelivr.net/gh/ineo6/homebrew-install/install)"
```

最后看到`==> Installation successful!`就说明安装成功了。

最最后执行：

```bash
brew update
```



### 如何卸载Homebrew

使用官方脚本同样会遇到`uninstall`地址无法访问问题，可以替换为下面脚本：

```bash
/usr/bin/ruby -e "$(curl -fsSL https://cdn.jsdelivr.net/gh/ineo6/homebrew-install/uninstall)"
```



### 修改镜像源

`brew`、`homebrew/core`是必备项目，`homebrew/cask`、`homebrew/bottles`按需设置。

通过 `brew config` 命令查看配置信息。

>  注意：
>
> - 如果使用zsh，则需要修改的脚本文件为`~/.zshrc` 
> - 如果使用bash，则需要修改的脚本文件为`~/.bash_profile` 



#### 中科大源

```bash
git -C "$(brew --repo)" remote set-url origin https://mirrors.ustc.edu.cn/brew.git

git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git

git -C "$(brew --repo homebrew/cask)" remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git

brew update

# 长期替换homebrew-bottles
echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles' >> ~/.bash_profile
source ~/.bash_profile
```

注意`bottles`可以临时设置，在终端执行下面命令：

```bash
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
```



#### 清华大学源

```bash
git -C "$(brew --repo)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git

git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git

git -C "$(brew --repo homebrew/cask)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git

brew update

# 长期替换homebrew-bottles
echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles' >> ~/.bash_profile
source ~/.bash_profile
```



#### 阿里云源

```bash
git -C "$(brew --repo)" remote set-url origin https://mirrors.aliyun.com/homebrew/brew.git

git -C "$(brew --repo homebrew/cask)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git

brew update

# 长期替换homebrew-bottles
echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles' >> ~/.bash_profile
source ~/.bash_profile
```



#### 恢复默认源

```bash
git -C "$(brew --repo)" remote set-url origin https://github.com/Homebrew/brew.git

git -C "$(brew --repo homebrew/core)" remote set-url origin https://github.com/Homebrew/homebrew-core.git

git -C "$(brew --repo homebrew/cask)" remote set-url origin https://github.com/Homebrew/homebrew-cask.git

brew update
```

`homebrew-bottles`配置只能手动删除，将 `~/.bash_profile` 文件中的 `HOMEBREW_BOTTLE_DOMAIN=https://mirrors.xxx.com`内容删除，并执行 `source ~/.bash_profile`。

