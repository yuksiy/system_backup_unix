#!/bin/bash

# ==============================================================================
#   機能
#     RSYNC_LOG_Nの内容をチェックする
#   構文
#     log_check_system_backup_unix.sh
#
#   Copyright (c) 2006-2017 Yukio Shiiya
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
SKIP_FAIL_MSG_CHECK_NO_LOG_FILE () {
	cat <<- EOF | ${INTCODE2DISP}
		-W (FAIL_MSG_CHECK) LOG_FILE not a file -- "${LOG_FILE}"
	EOF
}
SKIP_END_MSG_CHECK () {
	cat <<- EOF | ${INTCODE2DISP}
		-I 終了メッセージチェックが省略されました -- "${LOG_FILE}"
	EOF
}
SKIP_END_MSG_CHECK_NO_LOG_FILE () {
	cat <<- EOF | ${INTCODE2DISP}
		-W (END_MSG_CHECK) LOG_FILE not a file -- "${LOG_FILE}"
	EOF
}

MAIN_LOG_CHECK() {
	# 終了メッセージチェック
	MSG_PATTERN='-E "System backup job has ended."'
	CMD_INTCODE2EXT "${LOG_CHECK} ${MSG_PATTERN} \"${LOG_FILE}\""
	sleep 1
}

RSYNC_LOG_CHECK() {
	# 失敗メッセージチェック
	MSG_PATTERN='-F "^-W " -F "^-E "'
	CMD_INTCODE2EXT "${LOG_CHECK} ${MSG_PATTERN} \"${LOG_FILE}\""
	sleep 1
	# 終了メッセージチェック
	MSG_PATTERN='-E "-I rsync backup has ended successfully."'
	CMD_INTCODE2EXT "${LOG_CHECK} ${MSG_PATTERN} \"${LOG_FILE}\""
	sleep 1
}

RSYNC_LOG_CHECK_SKIP() {
	# 失敗メッセージチェック
	SKIP_FAIL_MSG_CHECK
	sleep 1
	# 終了メッセージチェック
	SKIP_END_MSG_CHECK
	sleep 1
}
RSYNC_LOG_CHECK_SKIP_NO_LOG_FILE() {
	# 失敗メッセージチェック
	SKIP_FAIL_MSG_CHECK_NO_LOG_FILE
	sleep 1
	# 終了メッセージチェック
	SKIP_END_MSG_CHECK_NO_LOG_FILE
	sleep 1
}

######################################################################
# メインルーチン
######################################################################

# MAIN_LOG チェック
LOG_FILE="${SCRIPT_TMP_DIR}/${MAIN_LOG}"
if [ "${MOUNT_TYPE}" = "local" -o "${MOUNT_TYPE}" = "remote" ];then
	MAIN_LOG_CHECK
fi

# RSYNC_LOG_N チェック
for N in 1 2
do
	RSYNC_LOG_N=RSYNC_LOG_${N}

	if [ ! "${!RSYNC_LOG_N}" = "" ];then
		LOG_FILE="${SCRIPT_TMP_DIR}/${!RSYNC_LOG_N}"
	else
		LOG_FILE="${RSYNC_LOG_N}"
	fi
	if [ "${MOUNT_TYPE}" = "local" -o "${MOUNT_TYPE}" = "remote" ];then
		if [ ! "${!RSYNC_LOG_N}" = "" ];then
			if [ -f "${LOG_FILE}" ];then
				RSYNC_LOG_CHECK
			else
				RSYNC_LOG_CHECK_SKIP_NO_LOG_FILE
			fi
		else
			RSYNC_LOG_CHECK_SKIP
		fi
	fi
done

