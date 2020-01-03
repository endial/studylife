#!/bin/sh

# 设置内存盘的名称
DISK_NAME=RamDisk
MOUNT_PATH=/Volumes/$DISK_NAME
# 设置备份文件的保存路径
WORK_PATH=/etc/RamDisk
BAK_PATH=$WORK_PATH/$DISK_NAME.tar.gz
LISTFILE=$WORK_PATH/list
LOGFILE=$WORK_PATH/log

# 设置最大的cache大小(MB)
MAX_CACHE_SIZE=128

# 备份Ramdisk内容，Downloads目录中超过128M的目录和文件直接不再保存
cd $MOUNT_PATH
declare -a fa
i=0
for file in $(du -s Downloads/* | sort -n)
do
  fa[$i]=$file
  let i=i+1
done
size=$((i/2))
echo "file number:"$size > $LOGFILE
cd $WORK_PATH
echo ".?*" > $LISTFILE
for((i=0;i<$size;i++))
do
  if ((${fa[$((i*2))]}<(($MAX_CACHE_SIZE*1024*2)) ));then
    echo "add:"${fa[$((i*2+1))]} >> $LOGFILE
  else
    echo ${fa[$((i*2+1))]} >> $LISTFILE
  fi
done
if [ -e $MOUNT_PATH ] ; then
    cd $MOUNT_PATH
    tar --exclude-from $LISTFILE -czf $BAK_PATH .
fi
