#!/bin/sh

# ==============================================================================
#   機能
#     ログメッセージを画面とログファイルに出力する
#   構文
#     system_backup_echo_log.sh ログファイル名 ログメッセージ
#
#   Copyright (c) 2012-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

echo "`date '+%Y/%m/%d %H:%M:%S'` $2" 2>&1 | tee -a "$1"

