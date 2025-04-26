# podman-composeのインストール
## pipのインストール
podman-composeをインストールするためには、まずpipが必要。dnfでインストールするので、以下コマンドで実行する。

```
./download_package.sh python3-pip
./install_package.sh python3-pip
```

## podman-composeのインストール
続いて、podman-composeのダウンロードを行う。パッケージファイルをダウンロードのみ行う場合は以下コマンドで実行可能。
`pip download -d ダウンロードしたいディレクトリ パッケージ名`

```
pip download -d /home/asuka/nutanix_mgmt_configuration/podman-compose/ podman-compose
```

ダウンロードが完了すると、当該フォルダにファイルが格納される。

```
$ pwd
/home/asuka/nutanix_mgmt_configuration/podman-compose

$ ls -lah
合計 796K
drwxr-xr-x. 2 asuka asuka 4.0K  4月 26 10:57 .
drwxr-xr-x. 7 asuka asuka  161  4月 26 10:59 ..
-rw-r--r--. 1 root  root  721K  4月 26 10:54 PyYAML-6.0.2-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl
-rw-r--r--. 1 asuka asuka  681  4月 26 11:03 README.md
-rw-r--r--. 1 root  root   41K  4月 26 10:54 podman_compose-1.3.0-py2.py3-none-any.whl
-rw-r--r--. 1 root  root   20K  4月 26 10:54 python_dotenv-1.1.0-py3-none-any.whl
```

## オフライン環境でのパッケージのインストール
ダウンロードした各種ファイルをオフライン環境へ移送する。
その後、pipのインストールとpodman-composeのインストールを行う。

```
$ ./install_package.sh python3-pip
$ cd podman-compose
$ pip install --no-index --find-links=./ podman-compose
Defaulting to user installation because normal site-packages is not writeable
Looking in links: ./
Requirement already satisfied: podman-compose in /usr/lib/python3.9/site-packages (1.0.6)
Requirement already satisfied: pyyaml in /usr/lib64/python3.9/site-packages (from podman-compose) (5.4.1)
Requirement already satisfied: python-dotenv in /usr/lib/python3.9/site-packages (from podman-compose) (0.19.2)
```

