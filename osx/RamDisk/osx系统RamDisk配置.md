[TOC]

# 说明

本目录中的脚本，主要用来为`Macbook osx`配置RamDisk。配置生成的 RamDisk 一般用于应用程序缓存，以减少 SSD 消耗；同时，稍微提升下性能。



主要包含两个文件：

- initramdisk.sh: 用来配置、生成并挂载 RamDisk；如果存在缓存备份，则恢复至 RamDisk
- syncramdisk.sh: 用来将 RamDisk 压缩并存储至磁盘，以进行缓存备份



## 安装

在`Terminal`中拷贝`RamDisk`目录及相应文件至`/etc`目录中：

```
sudo cp -rf RamDisk /etc/
```



## 配置

需要注意，如果修改配置，需要保证两个脚本中相应内容的一致性。



### initramdisk.sh 配置



#### 设置内存盘的名称及挂载路径

```
DISK_NAME=RamDisk
MOUNT_PATH=/Volumes/$DISK_NAME
```

需要保证该路径一定存在，如果不存在，需要手动创建。



#### 设置备份文件的保存路径

```
WORK_PATH=/etc/RamDisk
BAK_PATH=$WORK_PATH/$DISK_NAME.tar.gz
```

如果备份文件不存在，则创建一个空的 RamDisk。



#### 设置RamDisk的大小(MB)

```
DISK_SPACE=1024
```

该空间是在内存中分配，需要根据系统内存大小合理进行设置。



### syncramdisk.sh 配置



#### 设置内存盘的名称及挂载路径

```
DISK_NAME=RamDisk
MOUNT_PATH=/Volumes/$DISK_NAME
```



#### 设置备份文件的保存路径

```
WORK_PATH=/etc/RamDisk
BAK_PATH=$WORK_PATH/$DISK_NAME.tar.gz
LISTFILE=$WORK_PATH/list
```

备份文件在每次注销系统时自动生成并替换旧版本。



#### 设置最大的cache大小(MB)

```
MAX_CACHE_SIZE=50
```

RamDisk中会被归档的最大单个文件大小，用于避免存档较大文件。大量的大文件归档会增加关机及启动时间。



## 启用与禁用

### 使用 Hook 方式

正常使用RamDisk，需要为用户增加登录时自动挂载及注销时自动备份操作。主要使用系统的`Hook`功能。



- 查询当前Hook

```
sudo defaults read com.apple.loginwindow LoginHook
sudo defaults read com.apple.loginwindow LogoutHook
```

- 增加用户登录时Hook

```
sudo defaults write com.apple.loginwindow LoginHook /etc/RamDisk/initramdisk.sh
```

- 增加用户注销时Hook

```
sudo defaults write com.apple.loginwindow LogoutHook /etc/RamDisk/syncramdisk.sh
```

- 删除Hook（禁用RamDisk）

```
sudo defaults delete com.apple.loginwindow LoginHook
sudo defaults delete com.apple.loginwindow LogoutHook
```



### 使用 Plist 方式

增加开机自启动 Plist 文件`/Library/LaunchDaemons/com.none.Ramdisk.plist`,内容如下:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Ramdisk</key>
        <string>com.none.Ramdisk</string>
        <key>ProgramArguments</key>
        <array>
            <string>/etc/RamDisk/initramdisk.sh</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
    </dict>
</plist>
```

该方式配置的 Ramdisk 不会在系统退出时自动备份。使用与不需要备份临时数据的场景。



## 迁移应用缓存

如迁移 Google Chrome 缓存至 RamDisk 中。



- 创建 RamDisk 缓存目录

```
mkdir /Volumes/RamDisk/Caches
```

- 退出 Google Chrome

  迁移缓存文件之前，最好关闭应用，防止程序异常。

- 迁移Google缓存

```
cd ~/Library/Caches
mv Google /Volumes/RamDisk/Caches/; ln -sf /Volumes/RamDisk/Caches/Google ./
```



其他需要移到RamDisk的内容也可以如法炮制。



## 常见应用缓存位置

- Google Chrome：~/Library/Caches/Google
- Safari()