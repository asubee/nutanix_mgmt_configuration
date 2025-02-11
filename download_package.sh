#!/bin/bash

# 環境変数PKGの設定
source $HOME/nutanix_mgmt_configuration/conf.txt
PKG=$REPO_DIR/pkg
GET_PKG=$1

# 引数が与えられていない場合
if [ $# -eq 0 ]; then
    echo "エラー: ダウンロードするパッケージ名を指定してください。" >&2
    exit 1
fi

# 引数がある場合の処理
echo "$1と依存するパッケージをダウンロードします。"

# ローカルディレクトリを作成（存在しない場合）
mkdir -p $PKG

# ローカルリポジトリのファイルがあれば削除する

LOCAL_REPO_FILE=/etc/yum.repos.d/local-squid.repo

if [ -f "$LOCAL_REPO_FILE" ]; then
    sudo rm  "$LOCAL_REPO_FILE"
    echo "File $LOCAL_REPO_FILE has been deleted."
else
    echo "File $LOCAL_REPO_FILE does not exist."
fi

# yum-utils のインストールスクリプト
if rpm -q yum-utils > /dev/null 2>&1; then
    echo "yum-utils is already installed."
else
    echo "Installing yum-utils..."
    sudo dnf install -y yum-utils
    echo "yum-utils has been installed."
fi

# インストール状況を確認するための配列
installed_packages=()

# パッケージのインストール状況をチェック
for package in "${packages[@]}"; do
    if rpm -q "$package" &> /dev/null; then
        installed_packages+=("$package")
    fi
done

# dnfでsquidとその依存関係をダウンロード（インストールはしない）
sudo dnf install --releasever=9 --installroot=/tmp/httpd-installroot --downloadonly --downloaddir=$PKG $GET_PKG

#ローカルリポジトリの作成
createrepo $PKG

# ダウンロード完了メッセージ
echo "$GET_PKG and its dependencies have been downloaded to $PKG and the local repository has been created and registered."

