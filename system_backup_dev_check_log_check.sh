#!/bin/sh

# ==============================================================================
#   機能
#     log_check_system_backup_dev_check_unix.shのラッパースクリプト
#   構文
#     system_backup_dev_check_log_check.sh
#
#   Copyright (c) 2007-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
SCRIPT_FULL_NAME="`realpath $0`"
SCRIPT_ROOT="`dirname ${SCRIPT_FULL_NAME}`"
SCRIPT_NAME="`basename ${SCRIPT_FULL_NAME}`"

######################################################################
# 変数定義
######################################################################
# ユーザ変数
. "/usr/local/etc/system_backup/env.sh"
if [ $? -ne 0 ];then exit $?;fi

# システム環境 依存変数

# プログラム内部変数
LOG_CHECK_SYSTEM_BACKUP_DEV_CHECK_UNIX="${SCRIPT_ROOT}/log_check_system_backup_dev_check_unix.sh"

######################################################################
# メインルーチン
######################################################################

# 前回のログファイルの全削除
if [ ! "${DEV_CHECK_LOG}" = "" ];then rm -f "${DEV_CHECK_LOG}";fi

"${LOG_CHECK_SYSTEM_BACKUP_DEV_CHECK_UNIX}" 2>&1 | tee "${DEV_CHECK_LOG}"

