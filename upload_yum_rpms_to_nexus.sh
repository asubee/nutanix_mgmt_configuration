#!/bin/bash

# ========== 設定項目 ==========

NEXUS_URL="http://<NEXUS_HOST>:8081"       # 例：http://nexus.local:8081
REPO_NAME="my-yum-repo"                    # Nexus上のYUMリポジトリ名
PKG_DIR="/root/nutanix_mgmt_configuration/pkg"

USERNAME="admin"                           # Nexusユーザー名
PASSWORD="admin123"                        # パスワード

TMP_DIR="/tmp/nexus_yum_upload_$$"

# ========== 処理開始 ==========

set -e

# 一時作業用ディレクトリ作成
mkdir -p "$TMP_DIR"
cp "$PKG_DIR"/*.rpm "$TMP_DIR"

# createrepoでrepodata生成
echo "Generating YUM metadata with createrepo..."
createrepo "$TMP_DIR"

# アップロード関数
upload_file() {
    local file_path="$1"
    local relative_path="${file_path#$TMP_DIR/}"
    local upload_url="$NEXUS_URL/repository/$REPO_NAME/$relative_path"

    echo "Uploading $relative_path..."
    curl -u "$USERNAME:$PASSWORD" \
         --upload-file "$file_path" \
         "$upload_url"
}

# RPM + repodata をアップロード
echo "Uploading packages and repodata to Nexus..."
find "$TMP_DIR" -type f \( -name "*.rpm" -o -path "*/repodata/*" \) | while read -r file; do
    upload_file "$file"
done

# クリーンアップ
rm -rf "$TMP_DIR"

echo "✅ All RPMs and metadata uploaded to Nexus YUM repository successfully."
