#!/bin/bash

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

tmpdir=$(mktemp -d)
fetch_realm "$tmpdir" || exit 1
mv "$tmpdir/realm" /usr/local/bin/realm
rmdir "$tmpdir"

# Get version and save to /etc/realm/ver.txt
mkdir -p /etc/realm/
curl -s https://api.github.com/repos/zhboner/realm/releases/latest \
  | grep '"tag_name"' \
  | head -n1 \
  | sed -E 's/.*"tag_name":[[:space:]]*"([^"]+)".*/\1/' > /etc/realm/ver.txt

reset_config() {
mkdir -p /etc/realm/
cat > /etc/realm/config.toml <<EOF
[log]
level = "warn"

[dns]
mode = "ipv4_and_ipv6"
protocol = "tcp_and_udp"
min_ttl = 0
max_ttl = 60
cache_size = 5

[network]
no_tcp = false
use_udp = true
tcp_timeout = 300
udp_timeout = 30
send_proxy = false
send_proxy_version = 2
accept_proxy = false
accept_proxy_timeout = 5

[[endpoints]]
listen = "0.0.0.0:65333"
remote = "8.8.8.8:48085"

EOF
}

if [ -f /etc/realm/config.toml ]; then
	read -e -p "config.toml 文件已存在，是否覆盖？(y/N)" yn
	[[ -z "${yn}" ]] && yn="n"
	if [[ $yn == [Yy] ]]; then
		reset_config
	fi
else
	reset_config
	#echo "0 0 */6 * * ? * /usr/bin/systemctl restart realm" >> /var/spool/cron/crontabs/root
	#sync /var/spool/cron/crontabs/root
 	(crontab -l 2>/dev/null | grep -v "realm"; echo "0 0 */6 * * /usr/bin/systemctl restart realm") | crontab -
	#systemctl restart cron
fi

if [[ ! -f /etc/systemd/system/realm.service ]]; then
cat > /etc/systemd/system/realm.service <<EOF
[Unit]
Description=realm
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
WorkingDirectory=/etc/realm/
ExecStart=/usr/local/bin/realm -c /etc/realm/config.toml

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable realm
fi

systemctl restart realm

# echo "0 0 */6 * * ? * /usr/bin/systemctl restart realm" >> /var/spool/cron/crontabs/root
# sync /var/spool/cron/crontabs/root
# systemctl restart cron
