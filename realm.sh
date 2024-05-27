#!/bin/bash

wget -O /tmp/realm.tar.gz https://github.com/zhboner/realm/releases/download/v2.6.0/realm-x86_64-unknown-linux-gnu.tar.gz
tar -xvf /tmp/realm.tar.gz -C /usr/local/bin/
rm /tmp/realm.tar.gz
chmod +x /usr/local/bin/realm
mkdir -p /etc/realm/
cat > /etc/realm/config.toml <<EOF
[[endpoints]]

EOF
cat /etc/systemd/system/realm.service <<EOF
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
