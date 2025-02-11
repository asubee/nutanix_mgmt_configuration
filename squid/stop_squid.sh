#!/bin/bash

#環境変数の設定
CONF_FILE=/etc/squid/squid.conf

# 設定ファイルの戻し
sudo cp -r ./backup/squid.conf $CONF_FILE
sudo chown root:root $CONF_FILE
echo "squid.confの設定をリセットしました"

# firewallの戻し
echo "firewallの許可設定を元に戻します"
sudo firewall-cmd --remove-port=8080/tcp --permanent
sudo firewall-cmd --reload

echo "firewallの許可設定を元に戻しました"
sudo firewall-cmd --list-all

# サービスの停止
sudo systemctl stop squid
echo "squidを停止しました"

# サービス起動の無効化
sudo systemctl disable squid
echo "サービスの自動起動の設定を元に戻しました"

