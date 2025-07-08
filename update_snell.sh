#!/bin/bash

# 设置错误退出模式
set -e

# 定义系统架构检测函数
sysArch() {
    uname=$(uname -m)
    if [[ "$uname" == "i686" ]] || [[ "$uname" == "i386" ]]; then
        arch="i386"
    elif [[ "$uname" == *"armv7"* ]] || [[ "$uname" == "armv6l" ]]; then
        arch="armv7l"
    elif [[ "$uname" == *"armv8"* ]] || [[ "$uname" == "aarch64" ]]; then
        arch="aarch64"
    else
        arch="amd64"
    fi    
}

# 检测系统架构
sysArch

echo "检测到系统架构: $arch"

# 1. 下载版本文件并提取第一行到 ver 变量
echo "正在下载最新版本信息..."
wget -O /tmp/ver.txt https://raw.githubusercontent.com/gdyan2022/sth/main/ver.txt
ver=$(head -n 1 /tmp/ver.txt)
echo "最新版本: $ver"

# 2. 比较版本信息
if [[ -f "/etc/snell/ver.txt" ]]; then
    current_ver=$(head -n 1 /etc/snell/ver.txt)
    echo "当前版本: $current_ver"
    
    if [[ "$ver" == "$current_ver" ]]; then
        echo "版本相同，无需更新，退出脚本"
        rm /tmp/ver.txt
        exit 0
    fi
else
    echo "未找到当前版本文件，将进行新安装"
fi

# 3. 如果版本不同，执行更新
echo "版本不同，开始更新..."

# 下载新版本
echo "正在下载 Snell 服务器 v$ver..."
wget -O /tmp/snell-server.zip "https://dl.nssurge.com/snell/snell-server-${ver}-linux-${arch}.zip"

# 解压和安装
echo "正在解压..."
cd /tmp/
unzip -o snell-server.zip
chmod +x snell-server

# 清理下载的压缩包
rm /tmp/snell-server.zip

# 停止服务
echo "正在停止 Snell 服务..."
systemctl stop snell-server

# 移动新版本到目标位置
echo "正在安装新版本..."
mv /tmp/snell-server /usr/local/bin/

# 启动服务
echo "正在启动 Snell 服务..."
systemctl start snell-server

# 显示服务状态
echo "服务状态:"
systemctl status snell-server

# 更新版本记录
echo "正在更新版本记录..."
mkdir -p /etc/snell
echo "$ver" > /etc/snell/ver.txt

# 清理临时文件
rm /tmp/ver.txt

echo "Snell 服务器更新完成！" 
