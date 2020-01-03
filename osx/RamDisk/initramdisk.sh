#!/bin/sh

# 设置内存盘的名称
DISK_NAME=RamDisk
MOUNT_PATH=/Volumes/$DISK_NAME
# 设置备份文件的保存路径
WORK_PATH=/etc/RamDisk
BAK_PATH=$WORK_PATH/$DISK_NAME.tar.gz
# 设置分配给内存盘的空间大小(MB)
DISK_SPACE=4000

# 创建Ramdisk
if [ ! -e $MOUNT_PATH ]; then
    mkdir -p $MOUNT_PATH
fi

dev=`hdid -nomount ram://$(($DISK_SPACE*1024*2))`
newfs_hfs -v $DISK_NAME $dev
mount -o noatime,nosuid,-w,-m=777 -t hfs $dev $MOUNT_PATH    
chown endial:staff $MOUNT_PATH

# 恢复备份
if [ -s $BAK_PATH ]; then
    tar -zxf $BAK_PATH -C $MOUNT_PATH
fi
