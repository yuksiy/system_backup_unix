#!/bin/sh

# ==============================================================================
#   機能
#     log_check_system_backup_unix.shのラッパースクリプト
#   構文
#     system_backup_log_check.sh
#
#   Copyright (c) 2006-2017 Yukio Shiiya
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
LOG_CHECK_SYSTEM_BACKUP_UNIX="${SCRIPT_ROOT}/log_check_system_backup_unix.sh"

######################################################################
# メインルーチン
######################################################################

"${LOG_CHECK_SYSTEM_BACKUP_UNIX}" > "${SCRIPT_TMP_DIR}/${CHECK_LOG}" 2>&1

