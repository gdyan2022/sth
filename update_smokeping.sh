#!/bin/bash

set -e

CONFIG_DIR="/root/docker/smokeping/config"
VERSION_FILE="${CONFIG_DIR}/ver.txt"
REMOTE_VERSION_URL="https://raw.githubusercontent.com/gdyan2022/sth/main/smokeping/ver.txt"
BASE_URL="https://raw.githubusercontent.com/gdyan2022/sth/main/smokeping"

echo "==== Smokeping 配置更新检查 ===="
DATE_NOW=$(date "+%Y-%m-%d %H:%M:%S")
echo "时间: $DATE_NOW"

# 1. 获取远程版本号
REMOTE_VERSION=$(curl -fsSL "$REMOTE_VERSION_URL" | tr -d '\r\n')

if [[ -z "$REMOTE_VERSION" ]]; then
    echo "错误: 无法获取远程版本号"
    exit 1
fi

echo "远程版本号: $REMOTE_VERSION"

# 2. 读取本地版本号
if [[ -f "$VERSION_FILE" ]]; then
    LOCAL_VERSION=$(cat "$VERSION_FILE" | tr -d '\r\n')
else
    LOCAL_VERSION="0"
fi

echo "本地版本号: $LOCAL_VERSION"

# 3. 版本对比
if [[ "$REMOTE_VERSION" -le "$LOCAL_VERSION" ]]; then
    echo "版本无需更新"
    exit 0
fi

echo "发现新版本，开始更新 Smokeping 配置..."

# 4. 备份旧配置
BACKUP_DIR="${CONFIG_DIR}/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "${CONFIG_DIR}/"* "$BACKUP_DIR/" || true

echo "旧配置已备份到: $BACKUP_DIR"

# 5. 下载最新配置文件
wget -O "${CONFIG_DIR}/General"      "${BASE_URL}/General"
wget -O "${CONFIG_DIR}/Presentation" "${BASE_URL}/Presentation"
wget -O "${CONFIG_DIR}/Probes"       "${BASE_URL}/Probes"
wget -O "${CONFIG_DIR}/Targets"      "${BASE_URL}/Targets"

# 6. 写入新版本号
echo "$REMOTE_VERSION" > "$VERSION_FILE"

echo "配置更新完成，重启 Smokeping 容器..."

# 7. 重启容器
docker restart smokeping

echo "更新完成，新版本号: $REMOTE_VERSION"
