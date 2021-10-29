#!/bin/bash

# 配置 docker 加速
# curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s https://dockerhub.azk8s.cn
# curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://3272dd08.m.daocloud.io
# curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s https://docker.mirrors.ustc.edu.cn
# curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s https://b9pmyelo.mirror.aliyuncs.com
# my curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s https://v84jkad5.mirror.aliyuncs.com
# systemctl restart docker

function usage() {
  cat <<EOF
Usage: $0 command ...[parameters]....
    --help, -h                查看帮助信息
    --install                 {docker|docker-compose|harbor}
    --docker-data             docker数据目录
    --docker-home             docker安装目录($DOCKER_HOME/bin)
    --mirror                  指定镜像加速站点(已有默认配置)
    --get-docker-version      获取仓库软件版本号
    --version                 指定安装版本号
    --harbor-data             harbor数据目录
    --harbor-admin-pass       harbor管理员用户admin密码(default: admin)

    注意：所有软件默认安装最新稳定版本

    Exanple Docker:
      $0 --install docker
      $0 --install docker --docker-data /home/docker --docker-home /opt/docker
    
    Example docker-compose
        $0 --install compose

    Example Harbor
      $0 --install harbor --harbor-data /home/harbor/data

EOF
}

GETOPT_ARGS=`getopt -o hVd:v:i:d:m: -al help,get-docker-viersion,docker-data:,docker-home:,version:,mirror:,harbor-data:,harbor-admin-pass: -- "$@"`
eval set -- "$GETOPT_ARGS"
while [ -n "$1" ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -V|--get-docker-viersion)
            # curl -s http://mirror.azure.cn/docker-ce/linux/static/stable/x86_64/ | egrep -i -o 'href="docker-[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+' | sed 's/href="docker-//'
            curl -s 'https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/static/stable/x86_64/?C=M&O=A' | egrep -i -o 'href="docker-[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+' | sed 's/href="docker-//'
            exit 0
            ;;
        -i|--install)
            install=$2
            shift 2
            ;;
        -d|--docker-data)
            docker_data=$2
            shift 2
            ;;
        --docker-home)
            docker_home=$2
            shift 2
            ;;
        -v|--version)
            INSTALL_VERSION=$2
            shift 2
            ;;
        -m|--mirror)
            mirror=$2
            shift 2
            ;;
        --harbor-data)
            harbor_data=$2
            shift 2
            ;;
        --harbor-admin-pass)
            harbor_admin_pass=$2
            shift 2
            ;;
        --)
            shift
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done


# docker
SOURCE_DIR=/home
DEF_DOCKER_VER=18.09.8
INSECURE=${harbor:-192.168.2.30}
DOCKER_DATA=${docker_data:-/var/lib/docker}
DOCKER_HOME=${docker_home:-/usr/local/docker}
# MIRROR=${mirror:-http://3272dd08.m.daocloud.io}
# MIRROR=${mirror:-https://dockerhub.azk8s.cn}
# MIRROR=${mirror:-https://docker.mirrors.ustc.edu.cn}
MIRROR=${mirror:-https://b9pmyelo.mirror.aliyuncs.com}

# harbor
DEF_HARBOR_VER=v1.9.0
HARBOR_ADMIN_PASS=${harbor_admin_pass:-admin}
HARBOR_DATA_DIR=${harbor_data:-/home/harbor/data}

# docker-compose
DEF_COMPOSE_VER=1.24.1

# get github soft version
function get_version(){
    user=$1
    repo=$2
    repo_url="https://api.github.com/repos/$user/$repo/releases/latest"
    curl -sSL "$repo_url" | grep '"name"' | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g'
}

# get azure docker version
function get_compose_version(){
    curl -s http://mirror.azure.cn/docker-toolbox/linux/compose/ | egrep -i -o 'href="[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+' | awk -F '"' '{print $2}' | sort -t "." -k1n,1 -k2n,2 -k3n,3 | tail -n 1
}

function get_docker_version(){
    # curl -s http://mirror.azure.cn/docker-ce/linux/static/stable/x86_64/ | egrep -i -o 'href="docker-[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+' | sed 's/href="docker-//' | tail -n1
    curl -s 'https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/static/stable/x86_64/?C=M&O=A' | egrep -i -o 'href="docker-[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+' | sed 's/href="docker-//' | tail -n1
}

function install_docker(){
    # get docker version
    if [ -n "$INSTALL_VERSION" ]; then
        DOCKER_VER=$INSTALL_VERSION
    else
        if [ -z "$docker_version" ]; then
            docker_version=$(get_docker_version)
        fi
        DOCKER_VER=${docker_version:-$DEF_DOCKER_VER}
    fi

    # stop selinux
    setenforce 0
    sed -i 's#SELINUX=.*#SELINUX=disabled#' /etc/selinux/config

    # download soft
    DOCKER_URL="https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/static/stable/x86_64/docker-${DOCKER_VER}.tgz"
    # DOCKER_URL="http://mirror.azure.cn/docker-ce/linux/static/stable/x86_64/docker-${DOCKER_VER}.tgz"
    mkdir -p $SOURCE_DIR $DOCKER_HOME/bin
    cd $SOURCE_DIR

    echo -e "[INFO] \033[33mdownloading docker binaries\033[0m $DOCKER_VER"
    curl -C- -O --retry 3 "$DOCKER_URL" --progress || { echo "[ERROR] downloading docker failed"; exit 1; }

    #if [[ -f "./docker-${DOCKER_VER}.tgz" ]];then
    #	echo "[INFO] docker binaries already existed"
    #else
    #	echo -e "[INFO] \033[33mdownloading docker binaries\033[0m $DOCKER_VER"
    #	curl -C- -O --retry 3 "$DOCKER_URL" --progress || { echo "[ERROR] downloading docker failed"; exit 1; }
    #fi

    # 解压
    tar zxf $SOURCE_DIR/docker-${DOCKER_VER}.tgz -C $DOCKER_HOME/bin --strip-components 1
    ln -sf $DOCKER_HOME/bin/docker /bin/docker

    # 创建 docker 服务管理脚本
    echo "[INFO] generate docker service file"
    cat > /etc/systemd/system/docker.service <<-EOF
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
Environment="PATH=$DOCKER_HOME/bin:/bin:/sbin:/usr/bin:/usr/sbin"
ExecStart=$DOCKER_HOME/bin/dockerd
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=on-failure
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
KillMode=process


Delegate=yes
Restart=always
TimeoutStartSec=0
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF

    # 创建docker配置文件
    echo "[INFO] generate docker config file"
    echo "[INFO] prepare register mirror for $REGISTRY_MIRROR"
    mkdir -p $DOCKER_DATA /etc/docker
    cat > /etc/docker/daemon.json <<-EOF
{
  "registry-mirrors": ["$MIRROR"],
  "insecure-registries": ["$INSECURE"],
  "max-concurrent-downloads": 10,
  "live-restore": true,
  "log-driver": "json-file",
  "log-level": "warn",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
    },
  "data-root": "$docker_data"
}
EOF

    # 启动服务
    echo "[INFO] enable and start docker"
    systemctl enable docker
    systemctl daemon-reload
    systemctl restart docker

    # 验证
    # docker info
    docker --version
    if [ $? -eq 0 ]; then
        echo "[INFO] install successfully."
    else
        echo "[ERROR] install failed."
    fi

    # 命令补全
    if ! grep bash_completion ~/.bashrc >/dev/null 2>&1; then
        echo "[INFO] install bash_completion"
        curl -sSL https://gitee.com/yx571304/olz/raw/master/shell/docker/docker -o /etc/bash_completion.d/docker
        curl -sSL https://gitee.com/yx571304/olz/raw/master/shell/docker/bash_completion -o /usr/share/bash-completion/bash_completion
        echo -e "\nsource /usr/share/bash-completion/bash_completion" >> ~/.bashrc
        echo -e "[INFO] \033[33msource ~/.bashrc \033[0m"
    fi
}

function install_compose(){
    # get docker-compose version
    if [ -z "$compose_version" ]; then
        # compose_version=$(get_version docker compose)
        compose_version=$(get_compose_version)
    fi
    COMPOSE_VER=${compose_version:-$DEF_COMPOSE_VER}

    # 下载 / 解压 docker-compose
    echo -e "[INFO] \033[33mdownloading docker-compose binaries\033[0m $COMPOSE_VER"
    # COMPOSE_URL="https://get.daocloud.io/docker/compose/releases/download/$COMPOSE_VER/docker-compose-`uname -s`-`uname -m`"
    COMPOSE_URL="http://mirror.azure.cn/docker-toolbox/linux/compose/$COMPOSE_VER/docker-compose-`uname -s`-`uname -m`"
    curl -L $COMPOSE_URL > /usr/local/bin/docker-compose --progress
    chmod +x /usr/local/bin/docker-compose
    docker-compose version

    # docker-compose 命令补全
    curl -sSL https://gitee.com/yx571304/olz/raw/master/shell/docker/docker-compose -o /etc/bash_completion.d/docker-compose
}

function install_harbor(){
    # check docker
    if ! which docker >/dev/null ;then 2>&1
        echo "[ERROR] docker is not installed"
        echo "$0 -i docker"
        exit 1
    fi

    # check docer-compose
    if ! which docker-compose >/dev/null ;then 2>&1
        echo "[ERROR] docker-compose is not installed"
        echo "$0 -i docker-compose"
        exit 1
    fi

    # get harbor version
    if [ -z "$harbor_version" ]; then
        harbor_version=$(get_version goharbor harbor)
    fi
    HARBOR_VER=${harbor_version:-$DEF_HARBOR_VER}

    # 创建数据目录
    mkdir -p $SOURCE_DIR $HARBOR_DATA_DIR

    # 获取本机 IP
    HOST_IF=$(ip route|grep default|cut -d' ' -f5)
    HOST_IP=$(ip a|grep "$HOST_IF$"|awk '{print $2}'|cut -d'/' -f1)

    # 下载 / 解压源码
    cd $SOURCE_DIR
    echo -e "[INFO] \033[33mdownloading harbor\033[0m $HARBOR_VER"
    VER="$(echo $HARBOR_VER | tr -d '[a-z]' | cut -d. -f1,2).0"
    curl -O https://storage.googleapis.com/harbor-releases/release-${VER}/harbor-online-installer-${HARBOR_VER}.tgz
    tar xvf $SOURCE_DIR/harbor-online-installer-${HARBOR_VER}.tgz -C $SOURCE_DIR

    # 替换配置文件
    cp $SOURCE_DIR/harbor/harbor.yml $SOURCE_DIR/harbor/harbor.yml.default
    sed -i "s#harbor_admin_password:.*#harbor_admin_password: $HARBOR_ADMIN_PASS#" $SOURCE_DIR/harbor/harbor.yml
    sed -i "s#hostname:.*#hostname: $HOST_IP#" $SOURCE_DIR/harbor/harbor.yml
    sed -i "s#data_volume:.*#data_volume: $HARBOR_DATA_DIR#" $SOURCE_DIR/harbor/harbor.yml

    # 注释https
    sed -i '13 s@^@#&@' $SOURCE_DIR/harbor/harbor.yml
    sed -i '15 s@^@#&@' $SOURCE_DIR/harbor/harbor.yml
    sed -i '17 s@^@#&@' $SOURCE_DIR/harbor/harbor.yml
    sed -i '18 s@^@#&@' $SOURCE_DIR/harbor/harbor.yml

    # 安装
    echo -e "[INFO] \033[33m install harbor \033[0m"
    cd $SOURCE_DIR/harbor
    ./install.sh

    # info
    echo -e "[INFO] \033[33m\n \tUser: admin  Passwd: admin \033[0m"
}

case $install in
    docker)
        install_docker ;;
    compose)
        install_compose ;;
    harbor)
        install_harbor ;;
    *)
        usage
esac