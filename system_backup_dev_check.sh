#!/bin/sh

# ==============================================================================
#   機能
#     fs_check.shのラッパースクリプト
#   構文
#     system_backup_dev_check.sh
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
FS_CHECK="/usr/local/sbin/fs_check.sh"

######################################################################
# メインルーチン
######################################################################

# 前回のログファイルの全削除
if [ ! "${BKUP_CHECK_LOG_1}" = "" ];then rm -f "${BKUP_CHECK_LOG_1}";fi
if [ ! "${BKUP_CHECK_LOG_2}" = "" ];then rm -f "${BKUP_CHECK_LOG_2}";fi
if [ ! "${DEV_CHECK_LOG}"    = "" ];then rm -f "${DEV_CHECK_LOG}"   ;fi

if [ ! "${BKUP_DEV_1}" = "" ];then
	${FS_CHECK} "${BKUP_DEV_1}" ${BKUP_CHK_OPT_1} 2>&1 | tee "${BKUP_CHECK_LOG_1}"
	#if [ $? -ne 0 ];then exit 1;fi
fi
if [ ! "${BKUP_DEV_2}" = "" ];then
	${FS_CHECK} "${BKUP_DEV_2}" ${BKUP_CHK_OPT_2} 2>&1 | tee "${BKUP_CHECK_LOG_2}"
	#if [ $? -ne 0 ];then exit 1;fi
fi

