# NAT設定
## ポート転送の有効化
まず、RHEL9でIP転送を有効化するために、sysctl の設定を変更します。これにより、サーバがルータとしての役割を果たします。

```
# IP転送を有効にする
sudo sysctl -w net.ipv4.ip_forward=1

# 永続的に設定を反映するために /etc/sysctl.conf に追加
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
```

## NAT設定（パケット転送の設定）
次に、iptables または nftables を使用して、ポート転送の設定を行います。RHEL9では iptables の代わりに nftables が推奨されていますので、こちらを使用して設定します。

NAT設定のための nftables テーブルを作成します。設定ファイル`/etc/nftables.conf`を作成します。設定ファイルは以下の通り。

```
#!/usr/sbin/nft -f

# 表示用の設定
table inet my_filter {
    chain input {
        type filter hook input priority 0; policy drop;
        # Loopbackインターフェースの受け入れ
        iifname "lo" accept
        # 他の必要な設定を追加（例：SSHの許可）
    }

    chain forward {
        type filter hook forward priority 0; policy drop;
        # 172.25.73.65 に対する転送の許可
        iifname "eth1" oifname "eth0" accept
        iifname "eth0" oifname "eth1" accept
    }

    chain postrouting {
        type nat hook postrouting priority 100; policy accept;
        # NAT設定を追加（出力インターフェースに基づくNAT設定）
        oifname "eth1" masquerade
    }

    # ポート転送設定
    chain prerouting {
        type nat hook prerouting priority -100; policy accept;

        # 10.248.133.53:19440 → 172.25.73.245:9440
        tcp dport 19440 dnat to 172.25.73.245:9440

        # 10.248.133.53:29440 → 172.25.73.244:9440
        tcp dport 29440 dnat to 172.25.73.244:9440

        # 10.248.133.53:8443 → 172.25.73.68
        tcp dport 8443 dnat to 172.25.73.68
    }
}

```

設定を反映させるために、nftables サービスを再起動します。

```
# nftablesを再起動
sudo systemctl restart nftables
```

## routerの設定
まず、RHEL9 のネットワークインターフェース名を確認します。例えば、eth0 や eth1 という名前になっていることが多いです。

```
nmcli device status
```

これで、インターフェース名（eth0, eth1 など）を確認できます。
次に、nmcli コマンドを使って、172.25.73.65 経由で 10.248.133.0/24 へのルーティング設定を追加します。

```
sudo nmcli connection modify "インターフェース名" +ipv4.routes "10.248.133.0/24 172.25.73.65"
"インターフェース名" には、設定を追加したいインターフェース名（例えば eth1）を指定します。
``

"10.248.133.0/24" はルーティングする宛先ネットワーク、"172.25.73.65" はルータ（ゲートウェイ）の IP アドレスです。
変更を保存して反映するためには、インターフェースを再起動する必要があります。

```
sudo nmcli connection down "インターフェース名" && sudo nmcli connection up "インターフェース名"
```

