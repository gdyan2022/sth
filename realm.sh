#!/bin/bash

wget -O /tmp/realm.tar.gz https://github.com/zhboner/realm/releases/latest/realm-x86_64-unknown-linux-gnu.tar.gz
tar -xf /tmp/realm.tar.gz -C /usr/local/bin/
rm /tmp/realm.tar.gz
chmod +x /usr/local/bin/realm
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

#[[endpoints]]
#listen = "0.0.0.0:58085"
#remote = "8.8.8.8:48085"

EOF
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
DynamicUser=true
WorkingDirectory=/root
ExecStart=/usr/local/bin/realm -c /etc/realm/config.toml

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now realm

echo "0 0 */6 * * ? * /usr/bin/systemctl restart realm" >> /var/spool/cron/crontabs/root
sync /var/spool/cron/crontabs/root
systemctl restart cron
