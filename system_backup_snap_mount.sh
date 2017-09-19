#!/bin/bash

# ==============================================================================
#   機能
#     スナップショットの作成・マウント・情報取得
#   構文
#     system_backup_snap_mount.sh {1|2}
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
LVM_SNAPSHOT="/usr/local/sbin/lvm_snapshot.sh"

######################################################################
# 関数定義
######################################################################
SNAP_MOUNT() {
	# スナップショットのマウント解除
	echo "-I スナップショットのマウント解除の実行中..." | tee -a "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}"
	${LVM_SNAPSHOT} umount "${!SNAP_FS_LIST_N}" > /dev/null 2>&1
	# 終了コード判定は不要

	# スナップショットの削除
	echo "-I スナップショットの削除の実行中..." | tee -a "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}"
	${LVM_SNAPSHOT} remove "${!SNAP_FS_LIST_N}" > /dev/null 2>&1
	# 終了コード判定は不要

	# ファイルシステムバッファのフラッシュ
	echo "-I ファイルシステムバッファのフラッシュの実行中..." | tee -a "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}"
	sync;sync;sync >> "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}" 2>&1
	if [ $? -ne 0 ];then return 1;fi

	# スナップショットの作成
	echo "-I スナップショットの作成の実行中..." | tee -a "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}"
	${LVM_SNAPSHOT} create "${!SNAP_FS_LIST_N}" >> "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}" 2>&1
	if [ $? -ne 0 ];then return 1;fi

	# スナップショットのマウント
	echo "-I スナップショットのマウントの実行中..." | tee -a "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}"
	${LVM_SNAPSHOT} mount "${!SNAP_FS_LIST_N}" >> "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}" 2>&1
	if [ $? -ne 0 ];then return 1;fi

	# スナップショットの情報取得
	echo "-I スナップショットの情報取得の実行中..." | tee -a "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}"
	${LVM_SNAPSHOT} info "${!SNAP_FS_LIST_N}" >> "${SCRIPT_TMP_DIR}/${!SNAP_INFO_BEFORE_LOG_N}" 2>&1
	if [ $? -ne 0 ];then return 1;fi
}

######################################################################
# メインルーチン
######################################################################

if [ "${SYSTEM_BACKUP_RUN}" = "" ];then exit 0;fi
if [ ! -d "${SCRIPT_TMP_DIR}" ];then exit 0;fi

case $1 in
1|2)	N=$1;;
*)	exit 1;;
esac
SNAP_FS_LIST_N=SNAP_FS_LIST_${N}
SNAP_MOUNT_LOG_N=SNAP_MOUNT_LOG_${N}
SNAP_INFO_BEFORE_LOG_N=SNAP_INFO_BEFORE_LOG_${N}

# 前回のSNAP_MOUNT_LOG_N の削除
if [ -f "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}" ];then rm -f "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}";fi
# 前回のSNAP_INFO_BEFORE_LOG_N の削除
if [ -f "${SCRIPT_TMP_DIR}/${!SNAP_INFO_BEFORE_LOG_N}" ];then rm -f "${SCRIPT_TMP_DIR}/${!SNAP_INFO_BEFORE_LOG_N}";fi

# 処理開始メッセージの表示
echo "-I スナップショットの作成・マウント・情報取得を開始します" | tee -a "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}"

# スナップショットの作成・マウント・情報取得
SNAP_MOUNT
if [ $? -ne 0 ];then
	echo "-E スナップショットの作成・マウント・情報取得が異常終了しました" | tee -a "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}"
	exit 1
else
	echo "-I スナップショットの作成・マウント・情報取得が正常終了しました" | tee -a "${SCRIPT_TMP_DIR}/${!SNAP_MOUNT_LOG_N}"
	exit 0
fi

