#!/bin/bash

# 设置错误退出模式
set -e

# 下载可在本机运行的 realm 到目录 $1
# armv7/aarch64 用 musl 版；x86_64 先试标准 gnu 版，系统 glibc 太旧跑不起来时改用 gnu-glibc2.28 版
# realm 官方没有 i686 等 32 位 x86 的 Linux 版本，直接报错
fetch_realm() {
    local dir=$1 arch candidates
    case "$(uname -m)" in
        x86_64)          candidates="x86_64-unknown-linux-gnu x86_64-unknown-linux-gnu-glibc2.28" ;;
        *armv8*|aarch64) candidates="aarch64-unknown-linux-musl" ;;
        *armv7*|armv6l)  candidates="armv7-unknown-linux-musleabihf" ;;
        *) echo "不支持的架构: $(uname -m)" >&2; return 1 ;;
    esac
    for arch in $candidates; do
        echo "正在下载 realm-${arch}..."
        wget -O "$dir/realm.tar.gz" "https://github.com/zhboner/realm/releases/latest/download/realm-${arch}.tar.gz" || return 1
        tar -xzf "$dir/realm.tar.gz" -C "$dir" || return 1
        rm "$dir/realm.tar.gz"
        chmod +x "$dir/realm"
        # 不用 glibc 版本号比较，直接实测：glibc 不够时会报 GLIBC_x.xx not found
        if "$dir/realm" -v; then
            echo "选用 realm-${arch}"
            return 0
        fi
        echo "realm-${arch} 无法在本机运行，尝试下一个版本" >&2
    done
    echo "没有可在本机运行的 realm 版本" >&2
    return 1
}

echo "检测到系统架构: $(uname -m)"

# 1. 下载版本文件并提取第一行到 ver 变量
echo "正在下载最新版本信息..."
wget -O /tmp/realm_ver.txt https://raw.githubusercontent.com/gdyan2022/sth/main/realm_ver.txt
ver=$(head -n 1 /tmp/realm_ver.txt)
echo "最新版本: $ver"

# 2. 比较版本信息
if [[ -f "/etc/realm/ver.txt" ]]; then
    current_ver=$(head -n 1 /etc/realm/ver.txt)
    echo "当前版本: $current_ver"
    
    if [[ "$ver" == "$current_ver" ]]; then
        echo "版本相同，无需更新，退出脚本"
        rm /tmp/realm_ver.txt
        exit 0
    fi
else
    echo "未找到当前版本文件，将进行新安装"
fi

# 3. 如果版本不同，执行更新
echo "版本不同，开始更新..."

# 下载新版本
echo "正在下载 Realm 服务器 v$ver..."
tmpdir=$(mktemp -d)
fetch_realm "$tmpdir"

# 停止服务
echo "正在停止 Realm 服务..."
systemctl stop realm

# 移动新版本到目标位置
echo "正在安装新版本..."
mv "$tmpdir/realm" /usr/local/bin/
rmdir "$tmpdir"

# 启动服务
echo "正在启动 Realm 服务..."
systemctl start realm

# 显示服务状态
echo "服务状态:"
systemctl status realm

# 更新版本记录
echo "正在更新版本记录..."
mkdir -p /etc/realm
echo "$ver" > /etc/realm/ver.txt

# 清理临时文件
rm /tmp/realm_ver.txt

echo "Realm 服务器更新完成！"