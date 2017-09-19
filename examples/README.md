# examples

## 設定ファイルのインストール

下表に従って、サンプルファイル(=表中の必須/任意の後に続く括弧内のファイル)を元に内容を編集した上で、
各対象ホストに必要な設定ファイルをインストールしてください。

設定ファイル名                | インストール先ファイル名                               | ローカルバックアップのローカルホスト  | プルバックアップのローカルホスト  | プルバックアップのリモートホスト
----------------------------- | ------------------------------------------------------ | ------------------------------------- | --------------------------------- | ---------------------------------
バックアップ定義ファイル      | /usr/local/etc/system_backup/env.sh                    | 必須 (env.local.sh)                   |                                   | 必須 (env.pull.sh)
プルバックアップ定義ファイル  | /usr/local/etc/system_backup/env_pull.sh               |                                       | 必須 (env_pull.sh)                |
ファイルリスト取得スクリプト  | /usr/local/etc/system_backup/get_file_list.sh          | 必須 (get_file_list.sh)               |                                   | 必須 (get_file_list.sh)
バックアップスクリプト        | /usr/local/etc/system_backup/backup.sh                 | 必須 (backup.sh)                      |                                   |
バックアップソースリスト      | 任意 (backup.sh中の変数「RSYNC_SRC_LIST」で指定)       | 必須 (src_list_1.txt)                 |                                   |
プルバックアップスクリプト    | /usr/local/etc/system_backup/backup_pull.sh            |                                       | 必須 (backup_pull.sh)             |
プルバックアップソースリスト  | 任意 (backup_pull.sh中の変数「RSYNC_SRC_LIST」で指定)  |                                       | 必須 (src_list_1,2.txt)           |
サービス起動スクリプト        | 任意 (env.sh中の変数「SVC_START」で指定)               | 任意 (svc_start.sh)                   |                                   | 任意 (svc_start.sh)
サービス停止スクリプト        | 任意 (env.sh中の変数「SVC_STOP」で指定)                | 任意 (svc_stop.sh)                    |                                   | 任意 (svc_stop.sh)
リソース起動スクリプト        | 任意 (env.sh中の変数「RSC_START」で指定)               |                                       |                                   | 任意 (rsc_start.sh)
リソース停止スクリプト        | 任意 (env.sh中の変数「RSC_STOP」で指定)                |                                       |                                   | 任意 (rsc_stop.sh)
スナップショットリスト        | 任意 (env.sh中の変数「SNAP_FS_LIST_N」で指定)          | 任意 (snapshot_list_1.txt)            |                                   | 任意 (snapshot_list_1,2.txt)

## 設定ファイルの詳細

### バックアップ定義ファイル

#### MENU_DEFAULT

system_backup.sh を対話形式で起動した際に表示されるメニューのデフォルトの選択肢を指定します。

#### MENU_TIMEOUT

system_backup.sh を対話形式で起動した際に表示されるメニューのタイムアウト時間を秒数で指定します。

#### MOUNT_TYPE

バックアップ先デバイスが
ローカルの場合は「local」、リモートの場合は「remote」を指定します。

#### MOUNT_AUTO

バックアップ前/後にバックアップ先デバイスのマウント/マウント解除を
実行する場合は「TRUE」、実行しない場合は「FALSE」を指定します。

#### CHECK_AUTO

バックアップ後にバックアップ先デバイスのチェックを
実行する場合は「TRUE」、実行しない場合は「FALSE」を指定します。

#### BKUP_DEV_N, BKUP_DEV_FS_N, BKUP_MNT_N, BKUP_MNT_OPT_N, BKUP_UMNT_OPT_N, BKUP_CHK_OPT_N, BKUP_MOUNT_LOG_N, BKUP_UMOUNT_LOG_N, BKUP_CHECK_LOG_N

バックアップ先デバイスの以下のパラメータを指定します。

* デバイスファイル名
* ファイルシステム
* マウントディレクトリ名
* マウントオプション
* マウント解除オプション
* チェックオプション
* マウントログファイル名
* マウント解除ログファイル名
* チェックログファイル名

#### LOG_ROOT

ホスト別ログファイル格納ディレクトリの親ディレクトリ名を指定します。

#### LOG_DIR

ホスト別ログファイル格納ディレクトリ名を指定します。

#### DEST_ROOT

ホスト別バックアップ先ディレクトリの親ディレクトリ名を指定します。

#### DEST_DIR

ホスト別バックアップ先ディレクトリ名を指定します。

#### MAIN_LOG

メインログファイル名を指定します。

#### CHECK_LOG

チェックログファイル名を指定します。

#### DEV_CHECK_LOG

バックアップ先デバイスのチェックログファイル名を指定します。

#### RSYNC_LOG_N

rsync によるバックアップ処理のログファイル名を指定します。

#### SVC_START, SVC_STOP

バックアップ前/後にサービスの停止/起動を実行する場合、
以下のパラメータを指定します。

* サービス起動スクリプトのファイル名
* サービス停止スクリプトのファイル名

#### RSC_START, RSC_STOP

バックアップ前/後にリソースの停止/起動を実行する場合、
以下のパラメータを指定します。

* リソース起動スクリプトのファイル名
* リソース停止スクリプトのファイル名

#### SNAP_USE

バックアップ前/後にスナップショットのマウント/マウント解除を
実行する場合は「TRUE」、実行しない場合は「FALSE」を指定します。

#### SNAP_ROOT_N, SNAP_FS_LIST_N, SNAP_MOUNT_LOG_N, SNAP_INFO_BEFORE_LOG_N, SNAP_INFO_AFTER_LOG_N, SNAP_UMOUNT_LOG_N

バックアップ前/後にスナップショットのマウント/マウント解除を実行する場合、
以下のパラメータを指定します。

* スナップショットディレクトリツリーのルートディレクトリ名
* スナップショットリストのファイル名
* スナップショットのマウントログファイル名
* バックアップ前のスナップショット情報取得ログファイル名
* バックアップ後のスナップショット情報取得ログファイル名
* スナップショットのマウント解除ログファイル名

#### DOVECOT_MAINT_LOG

バックアップ前にDovecotのメンテナンスを実行する場合、
Dovecotのメンテナンスログファイル名を指定します。

#### GET_FILE_LIST_FIND_ARG_SUFFIX

ユーザデータファイルリストの取得を実行するためのパラメータを
以下の形式で指定します。

    "検索開始ディレクトリ,ユーザデータファイルリストのファイル名の接尾辞 ..."

#### GET_FILE_LIST_FIND_EXCLUDE

ユーザデータファイルリストから除外するファイル名のパターンを指定します。

#### LOG_MAIL

バックアップ後にログメールの送信を
実行する場合は「TRUE」、実行しない場合は「FALSE」を指定します。

#### LOG_MAIL_RECIPIENT, LOG_MAIL_SUBJECT, LOG_MAIL_CHARSET, DISPCODE2MAIL, SENDMAIL

バックアップ後にログメールの送信を実行する場合、
ログメールの以下のパラメータを指定します。

* 宛先
* 件名
* 文字コード
* 画面表示用文字コードをメール用文字コードに変換するためのコマンドライン
* メールを送信するためのコマンドライン

### プルバックアップ定義ファイル

必要に応じて内容を編集してください。

関連パッケージ:
* [remote_maint_common](https://github.com/yuksiy/remote_maint_common)

### ファイルリスト取得スクリプト

必要に応じて内容を編集してください。

関連パッケージ:
* [find_sort_pl](https://github.com/yuksiy/find_sort_pl)

### バックアップスクリプト, バックアップソースリスト, プルバックアップスクリプト, プルバックアップソースリスト

必要に応じて内容を編集してください。

関連パッケージ:
* [rsync_backup](https://github.com/yuksiy/rsync_backup)
* [remote_maint_common](https://github.com/yuksiy/remote_maint_common)

### サービス起動スクリプト, サービス停止スクリプト

必要に応じて内容を編集してください。

### リソース起動スクリプト, リソース停止スクリプト

必要に応じて内容を編集してください。

### スナップショットリスト

必要に応じて内容を編集してください。

関連パッケージ:
* [lvm_snapshot](https://github.com/yuksiy/lvm_snapshot)
