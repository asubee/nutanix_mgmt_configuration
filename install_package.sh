#!/bin/bash

# 環境変数PKGの設定
source $HOME/nutanix_mgmt_configuration/conf.txt
PKG=$REPO_DIR/pkg
GET_PKG=$1


# 引数が与えられていない場合
if [ $# -eq 0 ]; then
    echo "エラー: インストールするパッケージ名を指定してください。" >&2
    exit 1
fi

# 引数がある場合の処理
echo "$1をインストールします。"

# ローカルリポジトリを登録
cat <<EOF | sudo tee /etc/yum.repos.d/local-pkg.repo
[local-pkg]
name=Local Repository
baseurl=file://$PKG
enabled=1
gpgcheck=0
EOF

# rpmパッケージのインストール
sudo dnf install --disablerepo=* --enablerepo=local* -y $1

# すべてのファイルが正常にインストールされたかを検証

echo "$1 has been configured and started successfully."
