#!/bin/bash

# 脚本：将域名列表转换为dnsmasq格式
# 用法: ./convert_to_dnsmasq.sh [DNS_SERVER]
# 例如: ./convert_to_dnsmasq.sh 8.8.8.8

INPUT_FILE="stream.text.list"
OUTPUT_FILE="dnsmasq_rules.conf"
DEFAULT_DNS="1.1.1.1"
DOWNLOAD_URL="https://raw.githubusercontent.com/1-stream/1stream-public-utils/main/stream.text.list"

# 验证IP地址格式的函数
is_valid_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -ra ADDR <<< "$ip"
        for i in "${ADDR[@]}"; do
            if [[ $i -lt 0 || $i -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# 验证域名格式的函数
is_valid_domain() {
    local domain=$1
    # 简单的域名格式验证
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    fi
    return 1
}

# 处理DNS服务器参数
DNS_SERVER="$DEFAULT_DNS"
if [ $# -gt 0 ]; then
    if is_valid_ip "$1" || is_valid_domain "$1"; then
        DNS_SERVER="$1"
        echo "使用指定的DNS服务器: $DNS_SERVER"
    else
        echo "警告: '$1' 不是有效的IP地址或域名，使用默认DNS服务器: $DEFAULT_DNS"
    fi
else
    echo "使用默认DNS服务器: $DEFAULT_DNS"
fi

# 下载最新的域名列表
echo "正在从GitHub下载最新的域名列表..."
if command -v curl >/dev/null 2>&1; then
    if curl -s -o "$INPUT_FILE" "$DOWNLOAD_URL"; then
        echo "✓ 下载成功: $INPUT_FILE"
    else
        echo "✗ 下载失败，请检查网络连接"
        exit 1
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget -q -O "$INPUT_FILE" "$DOWNLOAD_URL"; then
        echo "✓ 下载成功: $INPUT_FILE"
    else
        echo "✗ 下载失败，请检查网络连接"
        exit 1
    fi
else
    echo "错误：需要安装 curl 或 wget 来下载文件"
    exit 1
fi

# 检查下载的文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误：下载的文件不存在"
    exit 1
fi

# 转换行结束符为Unix格式 (去除^M)
echo "正在处理行结束符..."
if command -v dos2unix >/dev/null 2>&1; then
    dos2unix "$INPUT_FILE" 2>/dev/null
    echo "✓ 已转换为Unix行结束符格式"
elif command -v sed >/dev/null 2>&1; then
    sed -i 's/\r$//' "$INPUT_FILE"
    echo "✓ 已使用sed转换行结束符"
else
    # 使用tr命令作为后备方案
    tr -d '\r' < "$INPUT_FILE" > "${INPUT_FILE}.tmp" && mv "${INPUT_FILE}.tmp" "$INPUT_FILE"
    echo "✓ 已使用tr转换行结束符"
fi

# 清空或创建输出文件
> "$OUTPUT_FILE"

echo "正在处理域名列表..."
echo "# DNSMasq配置文件 - 生成时间: $(date)" >> "$OUTPUT_FILE"
echo "# 使用DNS服务器: $DNS_SERVER" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 处理每一行
while IFS= read -r line; do
    # 跳过空行
    if [[ -z "$line" ]]; then
        continue
    fi
    
    # 跳过注释行（以#开头的行）
    if [[ "$line" =~ ^[[:space:]]*# ]]; then
        # 保留注释到输出文件
        echo "$line" >> "$OUTPUT_FILE"
        continue
    fi
    
    # 移除行首尾的空格和所有回车符
    domain=$(echo "$line" | tr -d '\r' | xargs)
    
    # 如果处理后的行不为空，则转换为dnsmasq格式
    if [[ -n "$domain" ]]; then
        echo "server=/$domain/$DNS_SERVER" >> "$OUTPUT_FILE"
    fi
    
done < "$INPUT_FILE"

# 创建目录
mkdir -p /etc/dnsmasq.d

# 复制规则文件
cp ./$OUTPUT_FILE /etc/dnsmasq.d/

# 备份原配置
cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak

# 写入新配置
cat > /etc/dnsmasq.conf << 'EOF'
cache-size=1000   # 缓存最多 1000 条记录
# 设置上游 DNS 服务器
server=1.1.1.1
server=1.0.0.1
expand-hosts
# 本地监听地址(可选)
listen-address=127.0.0.1
# 不读取 /etc/resolv.conf
no-resolv
strict-order
EOF

sed -i '/^nameserver 127.0.0.1$/d' /etc/resolv.conf
sed -i '0,/^[^#]/{/^[^#]/i\nameserver 127.0.0.1
}' /etc/resolv.conf
systemctl restart dnsmasq

echo ""
echo "转换完成！"
echo "输入文件: $INPUT_FILE (从GitHub下载)"
echo "输出文件: $OUTPUT_FILE"
echo "DNS服务器: $DNS_SERVER"
echo ""
echo "生成的dnsmasq配置文件内容预览："
echo "----------------------------------------"
head -20 "$OUTPUT_FILE"
echo "----------------------------------------"
echo ""
echo "脚本用法："
echo "  $0                    # 使用默认DNS服务器 $DEFAULT_DNS"
echo "  $0 8.8.8.8           # 使用Google DNS"
echo "  $0 dns.google        # 使用域名格式的DNS服务器"
