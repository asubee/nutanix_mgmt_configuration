#!/bin/bash

#依存パッケージ一覧の表示
sudo dnf list --installed | grep bind

# アンインストール
sudo dnf remove bind bind-dnssec-doc bind-dnssec-utils python3-bind python3-ply
