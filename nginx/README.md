# nginx

## selinuxのポート設定の確認
SELinuxで443ポートがどのように設定されているか確認する。http_port_tになっているので、Webサーバ（httpd）用に設定されている。

```
$ sudo semanage port -l | grep 443
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pki_ca_port_t                  tcp      829, 9180, 9701, 9443-9447
pki_kra_port_t                 tcp      10180, 10701, 10443-10446
pki_ocsp_port_t                tcp      11180, 11701, 11443-11446
pki_tks_port_t                 tcp      13180, 13701, 13443-13446
```

## Firewallの設定
firewalldが起動していることを確認する。activeなので有効化されている。

```
$ sudo systemctl is-active firewalld
active
```

設定を確認すると、いくつかのポートが開いていることがわかる。しかしhttps/443は開いていない。

```
sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: ens160
  sources:
  services: cockpit dhcpv6-client ssh
  ports: 
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

開いていないので443ポートを開ける。ここでは--add-port=443/tcpでポートを開けている。--add-service=httpsでも結果は同じだが、ポート番号がわかりやすく応用も利くポート番号指定にした。

```
$ firewall-cmd --add-port=443/tcp  --permanent --zone=public
```

リロードして設定を有効化する。
```
$ firewall-cmd --reload
success
```

再び設定を確認すると443ポートが空いていることがわかる。

```
sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: ens160
  sources:
  services: cockpit dhcpv6-client ssh
  ports: 443/tcp
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```



