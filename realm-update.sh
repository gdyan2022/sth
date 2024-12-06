#!/bin/bash

wget -O /tmp/realm.tar.gz https://github.com/zhboner/realm/releases/latest/download/realm-x86_64-unknown-linux-gnu.tar.gz
tar -xf /tmp/realm.tar.gz -C /usr/local/bin/
rm /tmp/realm.tar.gz
chmod +x /usr/local/bin/realm

systemctl restart realm
systemctl status realm
