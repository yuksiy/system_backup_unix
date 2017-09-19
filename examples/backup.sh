#!/bin/sh

######################################################################
# 基本設定
######################################################################
SCRIPT_FULL_NAME="`realpath $0`"
SCRIPT_ROOT="`dirname ${SCRIPT_FULL_NAME}`"
SCRIPT_NAME="`basename ${SCRIPT_FULL_NAME}`"

######################################################################
# 変数定義
######################################################################
# 第1引数のチェック
case $1 in
1|2)	N=$1;;
*)	exit 1;;
esac

# ユーザ変数
HOSTNAME=`hostname`

DEST_ROOT="${BKUP_MNT_1}/DAT"

RSYNC_SRC_LIST="/usr/local/etc/system_backup/src_list_1.txt"
RSYNC_DEST_DIR="${DEST_ROOT}/${HOSTNAME}"
RSYNC_EXCLUDE_LIST=""
RSYNC_PASSWD_FILE=""
RSYNC_SRC_PREFIX=""
RSYNC_CUT_DIRS_NUM=0
RSYNC_RETRY_NUM=0
RSYNC_RETRY_INTERVAL=5
RSYNC_WAIT_INTERVAL=0
RSYNC_OPTIONS="-vlpAogDt8"

# システム環境 依存変数

# プログラム内部変数
RSYNC_BACKUP=rsync_backup.sh

######################################################################
# メインルーチン
######################################################################

${RSYNC_BACKUP} -C ${RSYNC_CUT_DIRS_NUM} ${RSYNC_EXCLUDE_LIST:+-X ${RSYNC_EXCLUDE_LIST}} ${RSYNC_PASSWD_FILE:+-P ${RSYNC_PASSWD_FILE}} -t ${RSYNC_RETRY_NUM} -T ${RSYNC_RETRY_INTERVAL} -W ${RSYNC_WAIT_INTERVAL} ${RSYNC_OPTIONS:+-E "${RSYNC_OPTIONS}"} ${RSYNC_SRC_PREFIX:+-S "${RSYNC_SRC_PREFIX}"} ${RSYNC_SRC_LIST} ${RSYNC_DEST_DIR}

