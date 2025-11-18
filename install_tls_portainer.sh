#!/bin/bash

# 设置错误时退出
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}请使用root权限运行此脚本${NC}"
    exit 1
fi

# 获取域名参数
if [ -n "$1" ]; then
    DOMAIN="$1"
    echo -e "${GREEN}使用命令行参数域名: $DOMAIN${NC}"
else
    read -p "请输入域名: " DOMAIN
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}域名不能为空！${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}开始安装过程...${NC}"
echo -e "${YELLOW}域名: $DOMAIN${NC}"
echo ""

# 第一步：安装 acme.sh
echo -e "${GREEN}[1/3] 安装 acme.sh 及依赖...${NC}"
apt update && apt install -y socat

echo -e "${GREEN}[2/3] 下载并安装 acme.sh...${NC}"
curl https://get.acme.sh | sh -s email=gdyan2001@gmail.com

# 重新加载环境变量
source ~/.bashrc

# 申请证书
echo -e "${GREEN}[3/3] 申请 SSL 证书...${NC}"
/root/.acme.sh/acme.sh --issue --standalone -d "$DOMAIN" --force

# 检查证书是否申请成功
if [ ! -d "/root/.acme.sh/${DOMAIN}_ecc" ]; then
    echo -e "${RED}证书申请失败！请检查域名DNS解析是否正确指向本服务器${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}SSL 证书申请成功！${NC}"
echo ""

# 第二步：安装 Portainer
echo -e "${GREEN}开始安装 Portainer...${NC}"

# 创建 volume
docker volume create portainer_data

# 运行 Portainer 容器
docker run -d \
    -p 8000:8000 \
    -p 9443:9443 \
    --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    -v /root/.acme.sh/${DOMAIN}_ecc:/certs \
    portainer/portainer-ce:latest \
    --tlscert /certs/fullchain.cer \
    --tlskey /certs/${DOMAIN}.key

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}安装完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}访问地址: https://${DOMAIN}:9443${NC}"
echo -e "${YELLOW}请在浏览器中访问上述地址并设置管理员密码${NC}"
echo -e "${GREEN}========================================${NC}"
