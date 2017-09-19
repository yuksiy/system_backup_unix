# system_backup_unix

## 概要

システムのバックアップ (UNIX)

特徴は以下の通りです。

* 可能なバックアップパターン
  * ローカルホストのローカルバックアップ
  * リモートホストのプルバックアップ (非HAクラスタ/HAクラスタ)

* バックアップ前/後に実行可能な追加タスク
  * バックアップ先デバイスのマウント/マウント解除
  * サービス/リソースの停止/起動
  * スナップショットのマウント/マウント解除

* バックアップ前に実行可能な追加タスク
  * システム構成情報の取得
  * Dovecotのメンテナンス
  * ユーザデータファイルリストの取得

* バックアップ後に実行可能な追加タスク
  * バックアップ先デバイスのチェック
  * ログメールの送信

## 使用方法

### system_backup.sh

    ローカルホストをローカルバックアップします。
    # system_backup.sh

### system_backup_pull.sh

    非HAクラスタ構成のリモートホスト名「samba」をプルバックアップします。
    # system_backup_pull.sh samba

    HAクラスタ構成のリモートホスト名「www1」「www2」をプルバックアップします。
    # system_backup_pull.sh www1,www2

### その他

* 上記で紹介したツールの詳細については、「ツール名 --help」を参照してください。

* バックアップ先デバイスの初期設定(参考手順)に関しては、
  [hdd_setup_unix.txt ファイル](https://github.com/yuksiy/system_backup_unix/blob/master/hdd_setup_unix.txt)
  を参照してください。

* バックアップ先デバイスの交換方法(参考手順)に関しては、
  [hdd_change_unix.txt ファイル](https://github.com/yuksiy/system_backup_unix/blob/master/hdd_change_unix.txt)
  を参照してください。

## 動作環境

OS:

* Linux

依存パッケージ または 依存コマンド:

パッケージ名 または コマンド名                                       | ローカルバックアップのローカルホスト  | プルバックアップのローカルホスト  | プルバックアップのリモートホスト
-------------------------------------------------------------------- | ------------------------------------- | --------------------------------- | ---------------------------------
make (インストール目的のみ)                                          | 必須                                  | 必須                              | 必須
drbd                                                                 |                                       |                                   | 任意 (*1)
iconv                                                                | 必須                                  | 必須                              | 必須
openssh                                                              |                                       | 必須                              | 必須
pacemaker                                                            |                                       |                                   | 任意 (*1)
realpath                                                             | 必須                                  | 必須                              | 必須
rsync                                                                | 必須                                  | 必須                              | 必須
sendmailコマンド                                                     | 任意 (*2)                             |                                   | 任意 (*2)
smartmontools                                                        | 任意 (*3)                             |                                   | 任意 (*3)
[cmd_status_wait](https://github.com/yuksiy/cmd_status_wait)         |                                       |                                   | 任意 (*1)
[common_sh](https://github.com/yuksiy/common_sh)                     | 必須                                  | 必須                              | 必須
[dos_tools](https://github.com/yuksiy/dos_tools)                     | 必須                                  |                                   | 必須
[find_sort_pl](https://github.com/yuksiy/find_sort_pl)               | 必須                                  |                                   | 必須
[fs_tools_unix](https://github.com/yuksiy/fs_tools_unix)             | 必須                                  |                                   |
[get_info_unix](https://github.com/yuksiy/get_info_unix)             | 必須                                  |                                   | 必須
[log_check](https://github.com/yuksiy/log_check)                     | 必須                                  |                                   | 必須
[lvm_snapshot](https://github.com/yuksiy/lvm_snapshot)               | 任意 (*4)                             |                                   | 任意 (*4)
[remote_maint_common](https://github.com/yuksiy/remote_maint_common) |                                       | 必須                              |
[rsync_backup](https://github.com/yuksiy/rsync_backup)               | 必須                                  | 必須                              |

*1 … 該当ホストがHAクラスタ構成の場合のみ  
*2 … バックアップ後のログメールの送信機能を使用する場合のみ  
*3 … バックアップ先デバイスのS.M.A.R.T.情報を使用する場合のみ  
*4 … バックアップ時のスナップショット機能を使用する場合のみ  

## インストール

ソースからインストールする場合:

    (Linux の場合)
    # make install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

[examples/README.md ファイル](https://github.com/yuksiy/system_backup_unix/blob/master/examples/README.md)
を参照して設定ファイルをインストールしてください。

## 最新版の入手先

<https://github.com/yuksiy/system_backup_unix>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/system_backup_unix/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2006-2017 Yukio Shiiya
