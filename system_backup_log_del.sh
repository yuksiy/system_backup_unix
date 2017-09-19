#!/bin/sh

# ==============================================================================
#   機能
#     前回のログファイルを全削除する
#   構文
#     system_backup_log_del.sh
#
#   Copyright (c) 2006-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
trap "" 28				# TRAP SET
trap "POST_PROCESS;exit 1" 1 2 15	# TRAP SET

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
PAUSE="pause.sh"
SYSTEM_BACKUP_DEV_MOUNT="${SCRIPT_ROOT}/system_backup_dev_mount.sh"
SYSTEM_BACKUP_DEV_UMOUNT="${SCRIPT_ROOT}/system_backup_dev_umount.sh"

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	# バックアップ先デバイスのマウント
	if [ "${MOUNT_AUTO}" = "TRUE" ];then
		DEV_MOUNT
	elif [ "${MOUNT_AUTO}" = "FALSE" ];then
		# 実行しない
		:
	fi
}

POST_PROCESS() {
	# バックアップ先デバイスのマウント解除
	if [ "${MOUNT_AUTO}" = "TRUE" ];then
		DEV_UMOUNT
	elif [ "${MOUNT_AUTO}" = "FALSE" ];then
		# 実行しない
		:
	fi
}

# バックアップ先デバイスのマウント
DEV_MOUNT() {
	"${SYSTEM_BACKUP_DEV_MOUNT}"
	#if [ $? -ne 0 ];then DEV_MOUNT;fi
	#if [ "${DEBUG}" = "TRUE" ];then exit;fi
}

# バックアップ先デバイスのマウント解除
DEV_UMOUNT() {
	"${SYSTEM_BACKUP_DEV_UMOUNT}"
	#if [ $? -ne 0 ];then DEV_UMOUNT;fi
	#if [ "${DEBUG}" = "TRUE" ];then exit;fi
}

. yesno_function.sh

######################################################################
# メインルーチン
######################################################################

if [ "${LOG_ROOT}" = "" ];then exit 0;fi

# 作業開始前処理
PRE_PROCESS

for host in `\ls -F "${LOG_ROOT}/" | grep -e "/$" | grep -v -e "^\./$" -e "^\.\./$" | sed -e 's,/$,,'`
do
	# 削除対象ファイルの確認
	(set -x; ls -al "${LOG_ROOT}/${host}")

	# 削除確認
	echo "-Q Remove?" 1>&2
	YESNO
	# YES の場合
	if [ $? -eq 0 ];then
		for file in `find "${LOG_ROOT}/${host}" ! -type d | sort`
		do
			(set -x; rm -f "${file}")
		done
		for dir in `find "${LOG_ROOT}/${host}" -depth -type d`
		do
			if [ ! "${dir}" = "${LOG_ROOT}/${host}" ];then
				(set -x; rmdir "${dir}")
			fi
		done
		# 削除対象ファイルの確認
		(set -x; ls -al "${LOG_ROOT}/${host}")
	# NO の場合
	else
		echo "-W Skipping..." 1>&2
	fi
	#${PAUSE}
done

# 作業終了後処理
POST_PROCESS;exit 0

