#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
# 
# 此脚本为 Centos/Redhat 服务器批量部署服务器ssh key使用

#set -x

# 检测参数有效性
if test $# -lt 3; then
    echo -e "\nUsage: $0 <server ip> <username> <password> [ssh port]\n"
    exit 1
fi

# 安装工具 expect
[ -f /usr/bin/expect ] || yum install -y expect

server_list=$1
username=$2
password=$3
port=${4:-22}

# 检测当前 SSH Key 文件是否存在
sshkey_file=~/.ssh/id_rsa.pub
if ! test -e $sshkey_file; then
    expect -c "
    spawn ssh-keygen -t rsa
    expect \"Enter*\" { send \"\n\"; exp_continue; }
    "
fi

# 获取服务器列表
hosts="$server_list"
echo "================================================================================"
echo "hosts: $hosts"
echo ""

ssh_key_copy()
{
    # 删除历史 hosts 记录
    sed "/$1/d" -i ~/.ssh/known_hosts

    # 拷贝 SSH Key 文件，并在 known_hosts 文件中增加记录 
    expect -c "
    set timeout 100
    spawn ssh-copy-id -p $port $username@$1
    expect {
    \"yes/no\"   { send \"yes\n\"; exp_continue; }
    \"password\" { send \"$password\n\"; }
    \"already exist on the remote system\" { exit 1; }
    }
    expect eof
    "
}

# 自动部署 Key 文件
for host in $hosts; do
    echo "================================================================================"

    # 检测网络是否连通
    ping -i 0.2 -c 3 -W 1 $host >& /dev/null
    if test $? -ne 0; then
        echo "[ERROR]: Can't connect $host"
        exit 1
    fi

    cat /etc/hosts | grep -v '^#' | grep $host >& /dev/null
    if test $? -eq 0; then
        hostaddr=$(cat /etc/hosts | grep -v '^#' | grep $host | awk '{print $1}')
        hostname=$(cat /etc/hosts | grep -v '^#' | grep $host | awk '{print $2}')
        
        ssh_key_copy $hostaddr
        ssh_key_copy $hostname
    else
        ssh_key_copy $host
    fi

    echo ""
done
