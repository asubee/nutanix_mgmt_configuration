#!/bin/bash

#環境変数の設定
CONF_FILE=/etc/named.conf
ZONE_DIR=/var/named

# 設定ファイルの戻し
sudo cp -r ./backup/named.conf $CONF_FILE
sudo chown root:named $CONF_FILE

ZONE_FILES=$(ls ./conf/zonefile)
for FILE in $ZONE_FILES; do
 sudo rm $ZONE_DIR/$FILE
done

# firewallの戻し
sudo firewall-cmd --remove-service dns --permanent
sudo firewall-cmd --reload

# サービスの起動
sudo systemctl stop named

# サービス起動の有効化
sudo systemctl disable named

