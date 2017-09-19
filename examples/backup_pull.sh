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

# 第2引数のチェック
test "$2" = "" && exit 1 || host_fqdn="$2"
host="`echo ${host_fqdn} | awk -F'.' '{print $1}'`"

# ユーザ変数
DEST_ROOT="/BKUP/DAT"

case ${N} in
1)
	case ${host} in
	dns1|dns2|mail1|mail2|www1|www2|samba)
		RSYNC_SRC_LIST="/usr/local/etc/system_backup/src_list_1.txt"
		RSYNC_DEST_DIR="${DEST_ROOT}/${host}"
		;;
	*)
		exit 1
		;;
	esac
	;;
2)
	case ${host} in
	dns1|dns2|mail1|mail2|www1|www2)
		RSYNC_SRC_LIST="/usr/local/etc/system_backup/src_list_2.txt"
		case ${host} in
		dns1|dns2)	RSYNC_DEST_DIR="${DEST_ROOT}/dns";;
		mail1|mail2)	RSYNC_DEST_DIR="${DEST_ROOT}/mail";;
		www1|www2)	RSYNC_DEST_DIR="${DEST_ROOT}/www";;
		esac
		;;
	*)
		exit 1
		;;
	esac
	;;
esac
RSYNC_EXCLUDE_LIST=""
RSYNC_PASSWD_FILE=""
RSYNC_SRC_PREFIX="${host_fqdn}:"
RSYNC_CUT_DIRS_NUM=0
RSYNC_RETRY_NUM=0
RSYNC_RETRY_INTERVAL=5
RSYNC_WAIT_INTERVAL=0
RSYNC_OPTIONS="-vlpAogDt8 -e 'ssh -i /root/.ssh/id_rsa_remote_maint -l root' --iconv=UTF-8"

# システム環境 依存変数

# プログラム内部変数
RSYNC_BACKUP=rsync_backup.sh

######################################################################
# メインルーチン
######################################################################

${RSYNC_BACKUP} -C ${RSYNC_CUT_DIRS_NUM} ${RSYNC_EXCLUDE_LIST:+-X ${RSYNC_EXCLUDE_LIST}} ${RSYNC_PASSWD_FILE:+-P ${RSYNC_PASSWD_FILE}} -t ${RSYNC_RETRY_NUM} -T ${RSYNC_RETRY_INTERVAL} -W ${RSYNC_WAIT_INTERVAL} ${RSYNC_OPTIONS:+-E "${RSYNC_OPTIONS}"} ${RSYNC_SRC_PREFIX:+-S "${RSYNC_SRC_PREFIX}"} ${RSYNC_SRC_LIST} ${RSYNC_DEST_DIR}

