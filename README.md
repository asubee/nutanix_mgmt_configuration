# nutanix_mgmt_configuration

## パッケージのダウンロードとインストール
### 実行手順
オフライン環境での構築を想定し、必要なパッケージを事前にダウンロードしておく。
ダウンロードしたrpmを格納するデイレクトリ：pkg

まず、オンライン環境にて、以下スクリプトを実行する。なお、各フォルダの中にある`download_bind.sh`や`download_squid.sh`を実行してもよい。実行すると、依存関係にあるすべてのパッケージが`./pkg`にダウンロードされ、このフォルダがローカルリポジトリとして設定される。

```
（実行コマンド） ./download_package.sh <ダウンロードしたいパッケージ名>
今回は、dns（bind）とリバースプロキシ（squid）をダウンロードする為、以下コマンドを実行する。

$ ./download_package.sh bind
$ ./download_package.sh squid
```

続いて、ダウンロードしたファイル諸々をオフライン環境（今回構築するサーバ）に持って行き、以下スクリプトを実行することでパッケージをインストールする。
```
（実行コマンド） ./install_package.sh <インストールしたいパッケージ名>
今回は、dns（bind）とリバースプロキシ（squid）をインストールする為、以下コマンドを実行する。

$ ./install_package.sh bind
$ ./install_package.sh squid
```


### ダウンロードスクリプトの構成
ダウンロードスクリプトの構成は以下の通り（主要な部分のみ抜粋）。dnf installコマンドで、依存関係にあるすべてのパッケージをダウンロードのみ実行する。
* releasever：リリースバージョンを指定する。記載ではRHEL9系を指定
* installroot：インストールディレクトリを変更することで、通常では既にダウンロード済みのrpmはスキップされるところを、このコマンドで全パッケージダウンロードできるようにする。`/tmp/httpd-installroot`はダミーディレクトリで、実態が存在しなくても大丈夫。
* downloadonly：インストールせずにrpmのダウンロードのみ実行する
* downloaddir：rpmをダウンロードするフォルダ。環境変数で指定している通り、`/home/asuka/nutanix_mgmt_configuration/pkg`フォルダ配下にダウンロードする

最後にcreaterepoコマンドで、pkgフォルダ配下をローカルリポジトリに設定してメタデータを作成する。

```Shell : download_package.sh
#!/bin/bash
# 環境変数PKGの設定
REPO_DIR="/home/asuka/nutanix_mgmt_configuration"
source $HOME/nutanix_mgmt_configuration/conf.txt
PKG=$REPO_DIR/pkg
GET_PKG=$1

# dnfでsquidとその依存関係をダウンロード（インストールはしない）
sudo dnf install --releasever=9 --installroot=/tmp/httpd-installroot --downloadonly --downloaddir=$PKG $GET_PKG

#ローカルリポジトリの作成
createrepo $PKG
```

### インストールスクリプトの構成
インストールスクリプトの構成は以下の通り（主要な部分のみ抜粋）。本リポジトリのデータを事前にダウンロードし、オフライン環境の構築予定のサーバのhomeディレクトリに展開しておく。スクリプトの中で、展開したpkgフォルダ配下をローカルリポジトリとしてサーバに登録する。リポジトリの構成ファイルは`/etc/yum.repos.d/local-pkg.repo`という名前で作成する。
パッケージのインストールはdnf installコマンドで実行するが、使うレポジトリを今回登録したローカルレポジトリのみにするため、disablerepoですべてのリポジトリを無効にし、enablerepoでlocalで始まるリポジトリファイルのみを有効にする。

```
#!/bin/bash
# 環境変数PKGの設定
REPO_DIR="/home/asuka/nutanix_mgmt_configuration"
PKG=$REPO_DIR/pkg
GET_PKG=$1

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
```

## dnsの起動
今回、自宅のローカル環境（192.168.11.0/24）でdnsサーバを建てる。ドメイン名は`asubee.local`とする。名前解決は、ahv、cvm、PrismElement、PrismCentralの各々を実行する想定でconfファイル、zoneファイルを作成している。

### 実行手順
`./dns`フォルダに移動する。このフォルダ配下で、以下コマンドを実行することでインストールが始まる。先の手順でインストールが終わっていれば本スクリプトは実行不要。
```
./install_bind.sh
```

インストールが終わったらbind（namedデーモン）を起動する。
```
./start_bind.sh
```

終了する際には、以下スクリプトを実行する。
```
./stop_bind.sh
```

### スタートスクリプトの構成
dns（bind）の設定に必要なファイルはdns/confフォルダ配下に格納している。これらのファイルをnamed-checkconf、named-checkzoneコマンドを用いてチェックし、エラーがなければ指定のフォルダにコピーをする。その後、firewall-cmdでdnsサービスを有効化し、サービス（named）を起動している。

```
#!/bin/bash
#環境変数の設定
CONF_FILE=/etc/named.conf
ZONE_DIR=/var/named
NAMED_CONF=./conf/named.conf

# 設定ファイルの検証（エラーチェック）とコピー
sudo named-checkconf "$NAMED_CONF"
sudo cp -r ./conf/named.conf $CONF_FILE
sudo chown root:named $CONF_FILE
sudo chmod 640 $CONF_FILE

# zoneファイルの検証（エラーチェック）とコピー
sudo named-checkzone 11.168.192.in-addr.arpa ./conf/zonefile/11.168.192.in-addr.arpa.rev
sudo named-checkzone asubee.local ./conf/zonefile/asubee.local
sudo cp -r ./conf/zonefile/* $ZONE_DIR/
sudo chown root:named $ZONE_DIR/11.168.192.in-addr.arpa.rev
sudo chmod 640 $ZONE_DIR/asubee.local

# firewallの穴あけ
sudo firewall-cmd --permanent --add-service dns
sudo firewall-cmd --reload

# サービスの起動
sudo systemctl start named

# サービス起動の有効化
sudo systemctl enable named
```

### dnsの設定ファイルの構成
dns設定ファイルは以下の通り（重要な部分のみ抜粋）。
* listen-on ：port53でdnsサービスを起動し、dnsのリクエストはlocalhost（127.0.0.1）とDNSサーバのサービスLAN（192.168.11.99）のNICから受け付ける設定とする
* allow-query：192.168.11.0/24とlocalhostからのリクエストを受け付ける。それ以外のIPアドレスからはリクエストを受け付けない
* recursion no：再帰的なdns問い合わせ（今回定義するdnsレコード以外の任意のFQDNの名前解決を代理で受け付ける）を禁止する
* zone "asubee.local" ：正引きDNSの設定。type:masterでこのdnsがマスターであることを示し、zoneファイルはasubee.localに記載することを設定している
* zone "11.168.192.in-addr.arpa"：逆引きDNSの設定。zoneファイルは11.168.192.in-addr.arpa.revに記載することを設定している。逆引きのzoneファイルは、IPアドレスのネットワークアドレス部分を順番を逆に記載するのがセオリー。今回構築した環境では、192.168.11.0/24のIPアドレス帯における名前解決の仕組みなので、ファイル名は11.168.192~としている

```
options {
	listen-on port 53 { 
    127.0.0.1;
    192.168.11.99;
  };

	allow-query     { 192.168.11.0/24; localhost; };
	recursion no;

// add dnsserver setting
zone "asubee.local" IN {
  type master;
  file "asubee.local";
  allow-update { none; };
};

zone "11.168.192.in-addr.arpa" IN {
  type master;
  file "11.168.192.in-addr.arpa.rev";
  allow-update { none; };
};

```

### 正引きゾーンファイルの設定
正引きゾーンファイルは以下の通り。
* TTL：DNSサーバがゾーンファイルのデータをキャッシュする時間を指定（デフォルト：86400秒）
* @：ドメイン名を表す。このゾーンファイルでは @ は「 infraexpert.com 」と同じ意味を表す
* SOA DNSサーバ名 メールアドレス：DNSサーバー名と管理者のメールアドレス、DNSサーバーの各種設定を記述する。メールアドレスは@が使えないので代わりにドット"."で表す。なお、各URLの最後はピリオドで終わらすこと
* IN NS：dnsサーバのドメイン名を表すレコード。
* ahv01 IN A 192.168.11.10：名前解決する各レコード。このレコードだと、ahv01.asubee.localが192.168.11.10であることを表している

```
$TTL 86400
@ IN SOA ns1.asubee.local. hostmaster.asubee.local. (
    2022012401 ; serial
    1d         ; refresh period 10s default 1h
    3h         ; retry period 30s default 15m
    3d         ; expire default 7d 
    3h         ; min default 24h
)

                IN NS ns1.asubee.local.

ns1             IN A 192.168.11.99
ahv01           IN A 192.168.11.10
ahv02           IN A 192.168.11.11
ahv03           IN A 192.168.11.12
cvm01           IN A 192.168.11.13
cvm02           IN A 192.168.11.14
cvm03           IN A 192.168.11.15
element         IN A 192.168.11.16
central         IN A 192.168.11.17
```

### 逆引きゾーンファイル
逆引きゾーンファイルは以下の通り。DNSレコードを示す部分以外は正引きゾーンファイルと同様。
* 10 IN PTR ahv01.asubee.local.：逆引き名前解決する各レコード。このレコードだと、192.168.11.10がahv01.asubee.localであることを示す。各URLの最後はピリオドで終わらせること

```
$TTL 86400
@ IN SOA ns1.asubee.local. hostmaster.asubee.local. (
    2022012401 ; serial
    1d         ; refresh 1hr
    3h         ; retry 15min
    3d         ; expire 1w
    3h         ; min 24hr
)

      IN NS  ns1.asubee.local.
10    IN PTR ahv01.asubee.local.
11    IN PTR ahv02.asubee.local.
12    IN PTR ahv03.asubee.local.
13    IN PTR cvm01.asubee.local.
14    IN PTR cvm02.asubee.local.
15    IN PTR cvm03.asubee.local.
16    IN PTR element.asubee.local.
17    IN PTR central.asubee.local.
```

## squidの起動
### 実行手順
`./squid`フォルダに移動する。このフォルダ配下で、以下コマンドを実行することでインストールが始まる。先の手順でインストールが終わっていれば本スクリプトは実行不要。
```
./install_squid.sh
```

インストールが終わったらsquidを起動する。
```
./start_squid.sh
```

終了する際には、以下スクリプトを実行する。
```
./stop_squid.sh
```

### スタートスクリプトの構成
スタートスクリプトの設定は以下の通り。confファイル（squid.conf）を所定のディレクトリにコピーし、firewallの穴あけ（今回の設定ではプロキシは8080ポートでlistenするため）とsquidサービスの起動を実施している。

```
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
```

### squidの設定ファイルの構成
squid.confの設定は以下の通り。実際の設定ファイルから記載を抜粋してコメントを追記したので、各々の設定が何を指すのかはコメントを参照のこと。

```
# プロキシサーバへのリクエストを許可するIPアドレス帯の設定。localnetという変数にIPアドレスを設定している
acl localnet src 10.0.0.0/8		# RFC 1918 local private network (LAN)
acl localnet src 192.168.11.0/23	# RFC 1918 local private network (LAN)

# 許可するポート番号の指定。それぞれの変数にポート番号の値を格納している。
acl SSL_ports port 443
acl Safe_ports port 80		# http
acl Safe_ports port 443		# https

# Safe_ports以外のポート番号宛のリクエストは拒否する
http_access deny !Safe_ports

# SSL_ports以外のポート番号宛のSSL通信は拒否する
http_access deny CONNECT !SSL_ports

#プロキシサーバへのアクセスはlocalnet、localhostのみから許可する。
http_access allow localnet
http_access allow localhost
http_access deny all

# プロキシサーバをlistenするポート番号を指定する。デフォルトでは3128だがここでは8080に変更している
http_port 8080

# 上位プロキシ（検証環境では192.168.11.4）の指定
cache_peer 192.168.11.4 parent 8080 0 no-query
#上位プロキシサーバへ直接アクセスすることを禁止し、すべての通信を今回建てるプロキシサーバを経由するように強制する設定
never_direct allow all
```
