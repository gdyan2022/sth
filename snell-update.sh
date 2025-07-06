#!/bin/bash

wget -O /tmp/snell-server.zip https://dl.nssurge.com/snell/snell-server-v5.0.0b2-linux-amd64.zip
cd /tmp/
unzip snell-server.zip
chmod +x snell-server
rm /tmp/snell-server.zip
systemctl stop snell-server
mv /tmp/snell-server /usr/local/bin/

systemctl start snell-server
systemctl status snell-server
