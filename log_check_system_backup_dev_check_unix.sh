#!/bin/bash

# ==============================================================================
#   機能
#     BKUP_CHECK_LOG_Nの内容をチェックする
#   構文
#     log_check_system_backup_dev_check_unix.sh
#
#   Copyright (c) 2007-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
LANG=ja_JP.UTF-8

######################################################################
# 変数定義
######################################################################
# ユーザ変数
# 呼び出し元から継承

# システム環境 依存変数
EXTCODE2INT="iconv -f UTF-8 -t UTF-8"
INTCODE2EXT="iconv -f UTF-8 -t UTF-8"
INTCODE2DISP="iconv -f UTF-8 -t UTF-8"

# プログラム内部変数
#LOG_CHECK="sh -x log_check.sh"
LOG_CHECK="log_check.sh"

######################################################################
# 関数定義
######################################################################
CMD_INTCODE2EXT() {
	(eval "`echo \"$*\" | ${INTCODE2EXT}`" 2>&1 | ${INTCODE2DISP})
	return
}

SKIP_FAIL_MSG_CHECK () {
	cat <<- EOF | ${INTCODE2DISP}
		-I 失敗メッセージチェックが省略されました -- "${LOG_FILE}"
	EOF
}
SKIP_END_MSG_CHECK () {
	cat <<- EOF | ${INTCODE2DISP}
		-I 終了メッセージチェックが省略されました -- "${LOG_FILE}"
	EOF
}

BKUP_CHECK_LOG_CHECK_FAT() {
	# 失敗メッセージチェック
	MSG_PATTERN='-F "^-E " -F "Leaving file system unchanged." -F "Performing changes."'
	CMD_INTCODE2EXT "${LOG_CHECK} ${MSG_PATTERN} \"${LOG_FILE}\""
	sleep 1
	# 終了メッセージチェック
	MSG_PATTERN='-E "0 hidden sectors"'
	CMD_INTCODE2EXT "${LOG_CHECK} ${MSG_PATTERN} \"${LOG_FILE}\""
	sleep 1
}
BKUP_CHECK_LOG_CHECK_EXT() {
	# 失敗メッセージチェック
	MSG_PATTERN='-F "^-E " -F "UNEXPECTED INCONSISTENCY"'
	CMD_INTCODE2EXT "${LOG_CHECK} ${MSG_PATTERN} \"${LOG_FILE}\""
	sleep 1
	# 終了メッセージチェック
	MSG_PATTERN='-E "0 bad blocks"'
	CMD_INTCODE2EXT "${LOG_CHECK} ${MSG_PATTERN} \"${LOG_FILE}\""
	sleep 1
}
BKUP_CHECK_LOG_CHECK_SKIP() {
	# 失敗メッセージチェック
	SKIP_FAIL_MSG_CHECK
	sleep 1
	# 終了メッセージチェック
	SKIP_END_MSG_CHECK
	sleep 1
}

######################################################################
# メインルーチン
######################################################################

# BKUP_CHECK_LOG_N チェック
for N in 1 2
do
	BKUP_CHECK_LOG_N=BKUP_CHECK_LOG_${N}
	BKUP_DEV_N=BKUP_DEV_${N}
	BKUP_DEV_FS_N=BKUP_DEV_FS_${N}

	if [ ! "${!BKUP_CHECK_LOG_N}" = "" ];then
		LOG_FILE="${!BKUP_CHECK_LOG_N}"
	else
		LOG_FILE="${BKUP_CHECK_LOG_N}"
	fi
	if [ "${MOUNT_TYPE}" = "local" ];then
		if [ ! "${!BKUP_DEV_N}" = "" ];then
			case ${!BKUP_DEV_FS_N} in
			vfat)
				BKUP_CHECK_LOG_CHECK_FAT
				;;
			ext2|ext3|ext4)
				BKUP_CHECK_LOG_CHECK_EXT
				;;
			esac
		else
			BKUP_CHECK_LOG_CHECK_SKIP
		fi
	elif [ "${MOUNT_TYPE}" = "remote" ];then
		BKUP_CHECK_LOG_CHECK_SKIP
	fi
done

