#!/bin/bash

set -e

echo "==== Smokeping 自动部署脚本 ===="

# 1. 输入端口（默认 9080）
read -p "请输入 Smokeping 映射端口（默认 9080）: " PORT
PORT=${PORT:-9080}
echo "使用端口: $PORT"

# 2. 输入 display_name（默认 VPS）
read -p "请输入 Smokeping display_name（默认 VPS）: " DISPLAY_NAME
DISPLAY_NAME=${DISPLAY_NAME:-VPS}
echo "使用 display_name: $DISPLAY_NAME"

# 3. 检查 Docker 是否安装
if ! command -v docker >/dev/null 2>&1; then
    echo "Docker 未安装，开始安装 Docker..."

    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh

    echo "配置 Docker 用户组..."
    groupadd docker || true
    useradd docker -g docker || true
    usermod -aG docker $USER || true

    echo "Docker 安装完成，请重新登录 shell 以应用用户组权限"
else
    echo "Docker 已安装，跳过安装步骤"
fi

# 4. 创建 Smokeping 目录
echo "创建 Smokeping 目录..."
CONFIG_DIR="/root/docker/smokeping/config"
DATA_DIR="/root/docker/smokeping/data"

mkdir -p "$CONFIG_DIR"
mkdir -p "$DATA_DIR"

# 5. 如果容器已存在则删除
if docker ps -a --format '{{.Names}}' | grep -q "^smokeping$"; then
    echo "发现已有 Smokeping 容器，先移除..."
    docker rm -f smokeping
fi

# 6. 启动 Smokeping 容器
echo "启动 Smokeping 容器..."
docker run -d \
--name=smokeping \
-e TZ=Asia/Shanghai \
-p ${PORT}:80 \
-v ${CONFIG_DIR}:/config \
-v ${DATA_DIR}:/data \
--restart unless-stopped \
linuxserver/smokeping

# 7. 下载 Smokeping 配置文件
echo "下载 Smokeping 配置文件..."

BASE_URL="https://raw.githubusercontent.com/gdyan2022/sth/main/smokeping"

wget -O "${CONFIG_DIR}/General"      "${BASE_URL}/General"
wget -O "${CONFIG_DIR}/Presentation" "${BASE_URL}/Presentation"
wget -O "${CONFIG_DIR}/Probes"       "${BASE_URL}/Probes"
wget -O "${CONFIG_DIR}/Targets"      "${BASE_URL}/Targets"

echo "配置文件下载完成"

# 8. 修改 display_name
GENERAL_FILE="${CONFIG_DIR}/General"

if [ -f "$GENERAL_FILE" ]; then
    echo "修改 display_name 为: $DISPLAY_NAME"
    sed -i "s/^display_name\s*=.*/display_name = ${DISPLAY_NAME}/" "$GENERAL_FILE"
else
    echo "警告: 未找到 $GENERAL_FILE，跳过 display_name 修改"
fi

# 9. 重启容器加载配置
echo "重启 Smokeping 容器..."
docker restart smokeping

echo "==== Smokeping 部署完成 ===="
echo "访问地址：http://服务器IP:${PORT}"
echo "display_name = ${DISPLAY_NAME}"
