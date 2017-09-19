#!/bin/bash

# ==============================================================================
#   機能
#     システムをプルバックアップする
#   構文
#     USAGE 参照
#
#   Copyright (c) 2011-2017 Yukio Shiiya
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
# システム環境 依存変数 (共通)
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
export PATH=${PATH}:/usr/local/sbin:/usr/local/bin

# プログラム内部変数
SYSTEM_BACKUP="${SCRIPT_ROOT}/system_backup.sh"
SYSTEM_BACKUP_BACKUP_PULL="/usr/local/etc/system_backup/backup_pull.sh"

# DEBUG=TRUE
TMP_DIR="/var/run"
SYSTEM_BACKUP_TMP_DIR="${TMP_DIR}/system_backup.sh"

######################################################################
# 関数定義 (メインルーチン呼出し)
######################################################################
PRE_PROCESS() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ "${host_1_alive[${i}]}" = "1" ];then SSH ${host_fqdn_1[${i}]} "${SYSTEM_BACKUP} -f PRE_PROCESS"; fi
		if [ "${host_2_alive[${i}]}" = "1" ];then SSH ${host_fqdn_2[${i}]} "${SYSTEM_BACKUP} -f PRE_PROCESS"; fi
	done
}

INIT_MAIN_LOG() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ "${host_1_alive[${i}]}" = "1" ];then SSH ${host_fqdn_1[${i}]} "${SYSTEM_BACKUP} -f INIT_MAIN_LOG"; fi
		if [ "${host_2_alive[${i}]}" = "1" ];then SSH ${host_fqdn_2[${i}]} "${SYSTEM_BACKUP} -f INIT_MAIN_LOG"; fi
	done
}

SHOW_MSG_JOB_START() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ "${host_1_alive[${i}]}" = "1" ];then SSH_CMD ${host_fqdn_1[${i}]} "${SYSTEM_BACKUP} -f SHOW_MSG_JOB_START"; fi
		if [ "${host_2_alive[${i}]}" = "1" ];then SSH_CMD ${host_fqdn_2[${i}]} "${SYSTEM_BACKUP} -f SHOW_MSG_JOB_START"; fi
	done
}

GET_CONFIG_LIST() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ "${host_1_alive[${i}]}" = "1" ];then SSH_CMD ${host_fqdn_1[${i}]} "${SYSTEM_BACKUP} -f GET_CONFIG_LIST"; fi
		if [ "${host_2_alive[${i}]}" = "1" ];then SSH_CMD ${host_fqdn_2[${i}]} "${SYSTEM_BACKUP} -f GET_CONFIG_LIST"; fi
	done
}

STOP_SVC() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		# host_1 とhost_2 のうち、両方とも生きている場合
		if [ \( "${host_1_alive[${i}]}" = "1" \) -a \( "${host_2_alive[${i}]}" = "1" \) ];then
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f STOP_RSC"
				SSH_CMD  ${host_fqdn_standby[${i}]} "${SYSTEM_BACKUP} -f STOP_SVC"
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f STOP_SVC"
			else
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f STOP_SVC"
				SSH_CMD  ${host_fqdn_standby[${i}]} "${SYSTEM_BACKUP} -f STOP_SVC"
			fi
		# host_1 のみ生きている場合、またはhost_2 のみ生きている場合
		elif [ \( "${host_1_alive[${i}]}" = "1" \) -o \( "${host_2_alive[${i}]}" = "1" \) ];then
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f STOP_RSC"
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f STOP_SVC"
			else
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f STOP_SVC"
			fi
		fi
	done
}

SNAP_MOUNT() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		# host_1 とhost_2 のうち、両方とも生きている場合
		if [ \( "${host_1_alive[${i}]}" = "1" \) -a \( "${host_2_alive[${i}]}" = "1" \) ];then
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_CMD ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f SNAP_MOUNT_1"
				SSH_CMD ${host_fqdn_standby[${i}]} "${SYSTEM_BACKUP} -f SNAP_MOUNT_1,SNAP_MOUNT_2"
			else
				SSH_CMD ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f SNAP_MOUNT_1,SNAP_MOUNT_2"
				SSH_CMD ${host_fqdn_standby[${i}]} "${SYSTEM_BACKUP} -f SNAP_MOUNT_1,SNAP_MOUNT_2"
			fi
		# host_1 のみ生きている場合、またはhost_2 のみ生きている場合
		elif [ \( "${host_1_alive[${i}]}" = "1" \) -o \( "${host_2_alive[${i}]}" = "1" \) ];then
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_CMD ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f SNAP_MOUNT_1,SNAP_MOUNT_2"
			else
				SSH_CMD ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f SNAP_MOUNT_1,SNAP_MOUNT_2"
			fi
		fi
	done
}

START_SVC_SNAP_TRUE() {
	# ↓注意：「STOP_SVC」と逆順のループ
	for (( i=${host_group_count}; i>=1; i-- )) ; do
		# host_1 とhost_2 のうち、両方とも生きている場合
		if [ \( "${host_1_alive[${i}]}" = "1" \) -a \( "${host_2_alive[${i}]}" = "1" \) ];then
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f START_SVC_SNAP_TRUE"
				SSH_CMD  ${host_fqdn_standby[${i}]} "${SYSTEM_BACKUP} -f START_SVC_SNAP_TRUE"
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f START_RSC_SNAP_TRUE"
			else
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f START_SVC_SNAP_TRUE"
				SSH_CMD  ${host_fqdn_standby[${i}]} "${SYSTEM_BACKUP} -f START_SVC_SNAP_TRUE"
			fi
		# host_1 のみ生きている場合、またはhost_2 のみ生きている場合
		elif [ \( "${host_1_alive[${i}]}" = "1" \) -o \( "${host_2_alive[${i}]}" = "1" \) ];then
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f START_SVC_SNAP_TRUE"
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f START_RSC_SNAP_TRUE"
			else
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f START_SVC_SNAP_TRUE"
			fi
		fi
	done
}

START_SVC_SNAP_FALSE() {
	# ↓注意：「STOP_SVC」と逆順のループ
	for (( i=${host_group_count}; i>=1; i-- )) ; do
		# host_1 とhost_2 のうち、両方とも生きている場合
		if [ \( "${host_1_alive[${i}]}" = "1" \) -a \( "${host_2_alive[${i}]}" = "1" \) ];then
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f START_SVC_SNAP_FALSE"
				SSH_CMD  ${host_fqdn_standby[${i}]} "${SYSTEM_BACKUP} -f START_SVC_SNAP_FALSE"
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f START_RSC_SNAP_FALSE"
			else
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f START_SVC_SNAP_FALSE"
				SSH_CMD  ${host_fqdn_standby[${i}]} "${SYSTEM_BACKUP} -f START_SVC_SNAP_FALSE"
			fi
		# host_1 のみ生きている場合、またはhost_2 のみ生きている場合
		elif [ \( "${host_1_alive[${i}]}" = "1" \) -o \( "${host_2_alive[${i}]}" = "1" \) ];then
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f START_SVC_SNAP_FALSE"
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f START_RSC_SNAP_FALSE"
			else
				SSH_CMD  ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f START_SVC_SNAP_FALSE"
			fi
		fi
	done
}

GET_FILE_LIST() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ "${host_1_alive[${i}]}" = "1" ];then SSH_CMD ${host_fqdn_1[${i}]} "${SYSTEM_BACKUP} -f GET_FILE_LIST || true"; fi
		if [ "${host_2_alive[${i}]}" = "1" ];then SSH_CMD ${host_fqdn_2[${i}]} "${SYSTEM_BACKUP} -f GET_FILE_LIST || true"; fi
	done
}

SYSTEM_BACKUP_BACKUP() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		# host_1 とhost_2 のうち、両方とも生きている場合
		if [ \( "${host_1_alive[${i}]}" = "1" \) -a \( "${host_2_alive[${i}]}" = "1" \) ];then
			SSH_SYSTEM_BACKUP_BACKUP ${host_fqdn_active[${i}]}  1 ${RSYNC_LOG_1[${i}]}
			SSH_SYSTEM_BACKUP_BACKUP ${host_fqdn_standby[${i}]} 1 ${RSYNC_LOG_1[${i}]}
			SSH_SYSTEM_BACKUP_BACKUP ${host_fqdn_standby[${i}]} 2 ${RSYNC_LOG_2[${i}]}
		# host_1 のみ生きている場合、またはhost_2 のみ生きている場合
		elif [ \( "${host_1_alive[${i}]}" = "1" \) -o \( "${host_2_alive[${i}]}" = "1" \) ];then
			SSH_SYSTEM_BACKUP_BACKUP ${host_fqdn_active[${i}]}  1 ${RSYNC_LOG_1[${i}]}
			SSH_SYSTEM_BACKUP_BACKUP ${host_fqdn_active[${i}]}  2 ${RSYNC_LOG_2[${i}]}
		fi
	done
}

SNAP_UMOUNT() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		# host_1 とhost_2 のうち、両方とも生きている場合
		if [ \( "${host_1_alive[${i}]}" = "1" \) -a \( "${host_2_alive[${i}]}" = "1" \) ];then
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_CMD ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f SNAP_UMOUNT_1"
				SSH_CMD ${host_fqdn_standby[${i}]} "${SYSTEM_BACKUP} -f SNAP_UMOUNT_2,SNAP_UMOUNT_1"
			else
				SSH_CMD ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f SNAP_UMOUNT_2,SNAP_UMOUNT_1"
				SSH_CMD ${host_fqdn_standby[${i}]} "${SYSTEM_BACKUP} -f SNAP_UMOUNT_2,SNAP_UMOUNT_1"
			fi
		# host_1 のみ生きている場合、またはhost_2 のみ生きている場合
		elif [ \( "${host_1_alive[${i}]}" = "1" \) -o \( "${host_2_alive[${i}]}" = "1" \) ];then
			if [ ! "${share_fs_dir[${i}]}" = "" ];then
				SSH_CMD ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f SNAP_UMOUNT_2,SNAP_UMOUNT_1"
			else
				SSH_CMD ${host_fqdn_active[${i}]}  "${SYSTEM_BACKUP} -f SNAP_UMOUNT_2,SNAP_UMOUNT_1"
			fi
		fi
	done
}

SHOW_MSG_JOB_END() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ "${host_1_alive[${i}]}" = "1" ];then SSH_CMD ${host_fqdn_1[${i}]} "${SYSTEM_BACKUP} -f SHOW_MSG_JOB_END"; fi
		if [ "${host_2_alive[${i}]}" = "1" ];then SSH_CMD ${host_fqdn_2[${i}]} "${SYSTEM_BACKUP} -f SHOW_MSG_JOB_END"; fi
	done
}

OUTPUT_CHECK_LOG() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ "${host_1_alive[${i}]}" = "1" ];then SSH_CMD ${host_fqdn_1[${i}]} "${SYSTEM_BACKUP} -f OUTPUT_CHECK_LOG"; fi
		if [ "${host_2_alive[${i}]}" = "1" ];then SSH_CMD ${host_fqdn_2[${i}]} "${SYSTEM_BACKUP} -f OUTPUT_CHECK_LOG"; fi
	done
}

SHOW_CHECK_LOG() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ "${host_1_alive[${i}]}" = "1" ];then SSH_CMD ${host_fqdn_1[${i}]} "${SYSTEM_BACKUP} -f SHOW_CHECK_LOG"; fi
		if [ "${host_2_alive[${i}]}" = "1" ];then SSH_CMD ${host_fqdn_2[${i}]} "${SYSTEM_BACKUP} -f SHOW_CHECK_LOG"; fi
	done
}

SEND_LOG_MAIL() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ "${host_1_alive[${i}]}" = "1" ];then SSH ${host_fqdn_1[${i}]} "${SYSTEM_BACKUP} -f SEND_LOG_MAIL"; fi
		if [ "${host_2_alive[${i}]}" = "1" ];then SSH ${host_fqdn_2[${i}]} "${SYSTEM_BACKUP} -f SEND_LOG_MAIL"; fi
	done
}

DEL_LOG_PREV() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ "${host_1_alive[${i}]}" = "1" ];then
			IS_DIR_EMPTY ${LOG_ROOT}/${host_1[${i}]} || rm -f ${LOG_ROOT}/${host_1[${i}]}/*
		fi
		if [ "${host_2_alive[${i}]}" = "1" ];then
			IS_DIR_EMPTY ${LOG_ROOT}/${host_2[${i}]} || rm -f ${LOG_ROOT}/${host_2[${i}]}/*
		fi
	done
}

MOVE_LOG_NOW() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ "${host_1_alive[${i}]}" = "1" ];then
			SCP root@${host_fqdn_1[${i}]}:${SYSTEM_BACKUP_TMP_DIR}/* ${LOG_ROOT}/${host_1[${i}]}/
			SSH ${host_fqdn_1[${i}]} "rm -f ${SYSTEM_BACKUP_TMP_DIR}/*"
		fi
    	
		if [ "${host_2_alive[${i}]}" = "1" ];then
			SCP root@${host_fqdn_2[${i}]}:${SYSTEM_BACKUP_TMP_DIR}/* ${LOG_ROOT}/${host_2[${i}]}/
			SSH ${host_fqdn_2[${i}]} "rm -f ${SYSTEM_BACKUP_TMP_DIR}/*"
		fi
	done
}

POST_PROCESS() {
	for (( i=1; i<=${host_group_count}; i++ )) ; do
		if [ "${host_1_alive[${i}]}" = "1" ];then SSH ${host_fqdn_1[${i}]} "${SYSTEM_BACKUP} -f POST_PROCESS"; fi
		if [ "${host_2_alive[${i}]}" = "1" ];then SSH ${host_fqdn_2[${i}]} "${SYSTEM_BACKUP} -f POST_PROCESS"; fi
	done
}

######################################################################
# 関数定義 (非メインルーチン呼出し)
######################################################################
USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    system_backup_pull.sh [OPTIONS ...] "HOST_1[,HOST_2] ..." [FUNC_NAME,...]
		
		OPTIONS:
		    --help
		       Display this help and exit.
	EOF
}

SSH_SYSTEM_BACKUP_BACKUP() {
	host_fqdn="$1"
	N="$2"
	RSYNC_LOG="$3"
	if [ ! "${RSYNC_LOG}" = "" ];then
		SSH_CMD ${host_fqdn} "${SYSTEM_BACKUP} -f SYSTEM_BACKUP_BACKUP_${N}"
		${SYSTEM_BACKUP_BACKUP_PULL} ${N} ${host_fqdn} \
			> ${TMP_DIR}/${RSYNC_LOG} 2>&1
		SCP ${TMP_DIR}/${RSYNC_LOG} root@${host_fqdn}:${SYSTEM_BACKUP_TMP_DIR}/
		rm ${TMP_DIR}/${RSYNC_LOG}
	fi
}

. is_dir_empty_function.sh

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o \"\" -l help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE;exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	--help)
		USAGE;exit 0
		;;
	--)
		shift 1;break
		;;
	esac
done

# 第1引数のチェック
if [ ! "$1" = "" ];then
	HOST_GROUPS="$1"
else
	echo "-E Missing 1st argument" 1>&2
	USAGE;exit 1
fi

# 第2引数のチェック
if [ ! "$2" = "" ];then
	FUNC_NAMES="`echo \"$2\" | sed 's/,/ /g'`"
else
	FUNC_NAMES=""
fi

# プルバックアップ定義ファイルの読み込み(引数のチェック後)
. "/usr/local/etc/system_backup/env_pull.sh"
if [ $? -ne 0 ];then exit $?;fi

if [ "${FUNC_NAMES}" = "" ];then
	INIT_HOST_STAT || exit 1
	SHOW_HOST_STAT || exit 1
	PRE_PROCESS || exit 1
	INIT_MAIN_LOG || exit 1
	SHOW_MSG_JOB_START || exit 1
	GET_CONFIG_LIST || exit 1
	STOP_SVC || exit 1
	SNAP_MOUNT || exit 1
	START_SVC_SNAP_TRUE || exit 1
	GET_FILE_LIST || exit 1
	SYSTEM_BACKUP_BACKUP || exit 1
	SNAP_UMOUNT || exit 1
	START_SVC_SNAP_FALSE || exit 1
	SHOW_MSG_JOB_END || exit 1
	OUTPUT_CHECK_LOG || exit 1
	SHOW_CHECK_LOG || exit 1
	SEND_LOG_MAIL || exit 1
	DEL_LOG_PREV || exit 1
	MOVE_LOG_NOW || exit 1
	POST_PROCESS || exit 1
else
	for i in ${FUNC_NAMES} ; do
		func_name="`echo "${i}" | sed -n 's/^\([^:]\{1,\}\).*$/\1/;p'`"
		func_args="`echo "${i}" | sed -n 's/^[^:]\{1,\}\(.*\)$/\1/;s/:/ /g;p'`"
		case ${func_name} in
		*)	eval "${func_name} ${func_args} || exit 1";;
		esac
	done
fi

