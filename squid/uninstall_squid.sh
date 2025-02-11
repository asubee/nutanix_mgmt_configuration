#!/bin/bash

# 環境変数PKGの設定
PKG=$(pwd)/pkg

#依存パッケージ一覧の表示
sudo dnf list --installed | grep squid

# アンインストール
sudo dnf remove squid httpd-filesystem libecap perl-Digest-SHA perl-English
