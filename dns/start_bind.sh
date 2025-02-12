#!/bin/bash

#環境変数の設定
CONF_FILE=/etc/named.conf
ZONE_DIR=/var/named
NAMED_CONF=./conf/named.conf

# 設定ファイルの検証（エラーチェック）
sudo named-checkconf "$NAMED_CONF"

if [ $? -ne 0 ]; then
    echo "Error: Configuration file $NAMED_CONF contains errors. Exiting."
    exit 1
else
    echo "Configuration file $NAMED_CONF is valid."
fi

# 設定ファイルのコピーとパーミッション設定
sudo cp -r ./conf/named.conf $CONF_FILE
sudo chown root:named $CONF_FILE
sudo chmod 640 $CONF_FILE


# zoneファイルの検証（チェック）
ZONE_FILES=$(ls ./conf/zonefile)

for FILE in $ZONE_FILES; do
  if [[ "$FILE" == *.rev ]]; then
    # revファイルの場合の処理
    BASE_NAME=$(basename "$FILE" .rev)
    sudo named-checkzone $BASE_NAME ./conf/zonefile/$FILE
  else
    sudo named-checkzone $FILE ./conf/zonefile/$FILE
  fi

  if [ $? -ne 0 ]; then
    echo "Error: Zone file $FILE contains errors. Exiting."
    exit 1
  else
    echo "Zone file $FILE is valid."
  fi
done

# 設定ファイルのコピーとパーミッション設定
sudo cp -r ./conf/zonefile/* $ZONE_DIR/

for FILE in $ZONE_FILES; do
  sudo chown root:named $ZONE_DIR/$FILE
  sudo chmod 640 $ZONE_DIR/$FILE
done


# firewallの穴あけ
sudo firewall-cmd --permanent --add-service dns
sudo firewall-cmd --reload

# サービスの起動
sudo systemctl start named

# サービス起動の有効化
sudo systemctl enable named
