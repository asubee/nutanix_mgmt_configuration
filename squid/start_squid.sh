#!/bin/bash

#環境変数の設定
CONF_FILE=/etc/squid/squid.conf

# 設定ファイルの作成
sudo cp -r ./conf/squid.conf $CONF_FILE
sudo chmod 620 $CONF_FILE
sudo chown root:root $CONF_FILE

# firewallの穴あけ
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# サービスの起動
sudo systemctl start squid

# サービス起動の有効化
sudo systemctl enable squid
