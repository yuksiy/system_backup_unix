#!/bin/bash

# ==============================================================================
#   機能
#     システムをバックアップする
#   構文
#     USAGE 参照
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
PID=$$

######################################################################
# 変数定義
######################################################################
# ユーザ変数
. "/usr/local/etc/system_backup/env.sh"
if [ $? -ne 0 ];then exit $?;fi

# システム環境 依存変数 (共通)
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
export PATH=${PATH}:/usr/local/sbin:/usr/local/bin
MULTI_USER="2345"
DOVEADM="/usr/bin/doveadm"

# プログラム内部変数
export SYSTEM_BACKUP_RUN=set
CHOICE="choice.sh"
SYSTEM_BACKUP_DEV_CHECK="${SCRIPT_ROOT}/system_backup_dev_check.sh"
SYSTEM_BACKUP_DEV_CHECK_LOG_CHECK="${SCRIPT_ROOT}/system_backup_dev_check_log_check.sh"
SYSTEM_BACKUP_DEV_MOUNT="${SCRIPT_ROOT}/system_backup_dev_mount.sh"
SYSTEM_BACKUP_DEV_UMOUNT="${SCRIPT_ROOT}/system_backup_dev_umount.sh"
ECHO_LOG="${SCRIPT_ROOT}/system_backup_echo_log.sh"
GET_CONFIG_LIST="/usr/local/sbin/get_config_list.sh"
SYSTEM_BACKUP_GET_FILE_LIST="/usr/local/etc/system_backup/get_file_list.sh"
SYSTEM_BACKUP_LOG_CHECK="${SCRIPT_ROOT}/system_backup_log_check.sh"
SYSTEM_BACKUP_BACKUP="/usr/local/etc/system_backup/backup.sh"
SYSTEM_BACKUP_SNAP_MOUNT="${SCRIPT_ROOT}/system_backup_snap_mount.sh"
SYSTEM_BACKUP_SNAP_UMOUNT="${SCRIPT_ROOT}/system_backup_snap_umount.sh"

MODE="full"
FLAG_OPT_YES=FALSE
START_TIME=0							#初期状態が「0」でなければならない変数
FUNC_NAMES=""

RUNLEVEL=`runlevel | awk '{print $2}'`
echo "${RUNLEVEL}" | grep -q -e "^[${MULTI_USER}]$"
if [ $? -ne 0 ];then
	FLAG_MULTI_USER=FALSE
else
	FLAG_MULTI_USER=TRUE
fi

# DEBUG=TRUE
TMP_DIR="/var/run"
export SCRIPT_TMP_DIR="${TMP_DIR}/${SCRIPT_NAME}"
SCRIPT_LOCK_FILE="${TMP_DIR}/${SCRIPT_NAME}.lock"
SVC_LOG_TMP="${SCRIPT_TMP_DIR}/svc_log.tmp"
RSC_LOG_TMP="${SCRIPT_TMP_DIR}/rsc_log.tmp"
LOG_MAIL_TMP="${SCRIPT_TMP_DIR}/log_mail.tmp"

######################################################################
# 関数定義 (単独実行可)
######################################################################
# 作業開始前処理
PRE_PROCESS() {
	# ロックファイルの作成
	if [ -f "${SCRIPT_LOCK_FILE}" ];then
		echo "-E lock file already exists -- ${SCRIPT_LOCK_FILE}" 1>&2
		exit 1
	else
		:> "${SCRIPT_LOCK_FILE}"
	fi
	# 前回の一時ディレクトリの削除
	if [ -d "${SCRIPT_TMP_DIR}" ];then
		# ディレクトリが空でない(=想定外の)場合も削除される
		rm -fr "${SCRIPT_TMP_DIR}"
	fi
	# 一時ディレクトリの作成
	mkdir -p "${SCRIPT_TMP_DIR}"
}

# 作業終了後処理
POST_PROCESS() {
	# 一時ディレクトリの削除
	if [ ! "${DEBUG}" = "TRUE" ];then
		if [ -d "${SCRIPT_TMP_DIR}" ];then
			# ディレクトリが空でない(=想定外の)場合も削除される
			# rm -fr "${SCRIPT_TMP_DIR}"
			# ディレクトリが空でない(=想定外の)場合は削除されない
			rmdir "${SCRIPT_TMP_DIR}"
		fi
	fi
	# ロックファイルの削除
	rm -f "${SCRIPT_LOCK_FILE}"
}

# 指定時間の待機
WAIT_START_TIME() {
	if [ ${START_TIME} -ge 1 ];then
		if [ "${FLAG_MULTI_USER}" = "TRUE" ];then
			if [ ! "${RSC_STOP}" = "" ];then
				wall <<- EOF
					Resources listed in the following file are going DOWN by system backup job in ${START_TIME} minutes!
					  ${RSC_STOP}
				EOF
			fi
			if [ ! "${SVC_STOP}" = "" ];then
				wall <<- EOF
					Services listed in the following file are going DOWN by system backup job in ${START_TIME} minutes!
					  ${SVC_STOP}
				EOF
			fi
			sleep `expr ${START_TIME} \* 60`
		fi
	fi
}

# 前回のログファイルの全削除
DEL_LOG_PREV() {
	if [ ! "${LOG_DIR}" = "" ];then
		rm -fr "${LOG_DIR}"/*
	fi
	#if [ ! "${BKUP_MOUNT_LOG_1}"  = "" ];then rm -f "${BKUP_MOUNT_LOG_1}" ;fi
	#if [ ! "${BKUP_MOUNT_LOG_2}"  = "" ];then rm -f "${BKUP_MOUNT_LOG_2}" ;fi
	#if [ ! "${BKUP_UMOUNT_LOG_1}" = "" ];then rm -f "${BKUP_UMOUNT_LOG_1}";fi
	#if [ ! "${BKUP_UMOUNT_LOG_2}" = "" ];then rm -f "${BKUP_UMOUNT_LOG_2}";fi
	if [ ! "${BKUP_CHECK_LOG_1}"  = "" ];then rm -f "${BKUP_CHECK_LOG_1}" ;fi
	if [ ! "${BKUP_CHECK_LOG_2}"  = "" ];then rm -f "${BKUP_CHECK_LOG_2}" ;fi
	if [ ! "${DEV_CHECK_LOG}"     = "" ];then rm -f "${DEV_CHECK_LOG}"    ;fi
}

# 今回のログファイルの全移動
MOVE_LOG_NOW() {
	if [ ! "${LOG_DIR}" = "" ];then
		mv "${SCRIPT_TMP_DIR}"/* "${LOG_DIR}"/ >/dev/null 2>&1
	fi
}

# MAIN_LOG の初期化
INIT_MAIN_LOG() {
	OUTPUT_FILE_HEADER > "${SCRIPT_TMP_DIR}/${MAIN_LOG}" 2>&1
}

# ジョブ開始メッセージの表示
SHOW_MSG_JOB_START() {
	${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "System backup job has started."
}

# ジョブ終了メッセージの表示
SHOW_MSG_JOB_END() {
	${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "System backup job has ended."
	# 画面とMAIN_LOG に改行を追加出力
	echo | tee -a "${SCRIPT_TMP_DIR}/${MAIN_LOG}"
}

# サービスの起動 (スナップショットを使用する場合)
START_SVC_SNAP_TRUE() {
	N=$1
	if [ "${SNAP_USE}" = "TRUE" ];then
		START_SVC_SUB
	fi
}

# サービスの起動 (スナップショットを使用しない場合)
START_SVC_SNAP_FALSE() {
	N=$1
	if [ ! "${SNAP_USE}" = "TRUE" ];then
		START_SVC_SUB
	fi
}

# サービスの停止
STOP_SVC() {
	N=$1
	STOP_SVC_SUB
}

# リソースの起動 (スナップショットを使用する場合)
START_RSC_SNAP_TRUE() {
	if [ "${SNAP_USE}" = "TRUE" ];then
		START_RSC_SUB
	fi
}

# リソースの起動 (スナップショットを使用しない場合)
START_RSC_SNAP_FALSE() {
	if [ ! "${SNAP_USE}" = "TRUE" ];then
		START_RSC_SUB
	fi
}

# リソースの停止
STOP_RSC() {
	STOP_RSC_SUB
}

# システム構成情報の取得
GET_CONFIG_LIST() {
	${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "システム構成情報の取得中..."
	"${GET_CONFIG_LIST}" "${SCRIPT_TMP_DIR}"
}

# ユーザデータファイルリストの取得
GET_FILE_LIST() {
	"${SYSTEM_BACKUP_GET_FILE_LIST}"
}

# Dovecotのメンテナンス
DOVECOT_MAINT() {
	if [ ! "${DOVECOT_MAINT_LOG}" = "" ];then
		${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "Dovecotのメンテナンス中..."
		if [ -x ${DOVEADM} ];then
			(set -x; ${DOVEADM} purge -A) > ${SCRIPT_TMP_DIR}/${DOVECOT_MAINT_LOG} 2>&1
		fi
	fi
}

# DOVECOT_MAINT_LOG の表示
SHOW_DOVECOT_MAINT_LOG() {
	if [ ! "${DOVECOT_MAINT_LOG}" = "" ];then
		cat "${SCRIPT_TMP_DIR}/${DOVECOT_MAINT_LOG}" 2>&1 | sed 's#^#  #' | tee -a "${SCRIPT_TMP_DIR}/${MAIN_LOG}"
	fi
}

# バックアップ処理
SYSTEM_BACKUP_BACKUP() {
	N=$1
	RSYNC_LOG_N=RSYNC_LOG_${N}
	if [ ! "${!RSYNC_LOG_N}" = "" ];then
		${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "バックアップ処理(${N})の実行中..."
		if [ -x ${SYSTEM_BACKUP_BACKUP} ];then
			${SYSTEM_BACKUP_BACKUP} ${N} > ${SCRIPT_TMP_DIR}/${!RSYNC_LOG_N} 2>&1
		fi
	fi
}

# バックアップ先デバイスのチェック
DEV_CHECK() {
	if [ "${CHECK_AUTO}" = "TRUE" ];then
		if [ "${MOUNT_TYPE}" = "local" ];then
			# バックアップ先デバイスのマウント解除
			DEV_UMOUNT_SUB 2>&1 | tee -a "${SCRIPT_TMP_DIR}/${MAIN_LOG}"
			# バックアップ先デバイスのチェック
			DEV_CHECK_SUB
			# バックアップ先デバイスのマウント
			DEV_MOUNT_SUB 2>&1 | tee -a "${SCRIPT_TMP_DIR}/${MAIN_LOG}"
		elif [ "${MOUNT_TYPE}" = "remote" ];then
			# 実行しない
			:
		fi
	elif [ "${CHECK_AUTO}" = "FALSE" ];then
		# 実行しない
		:
	fi
}

# バックアップ先デバイスのマウント
DEV_MOUNT() {
	if [ "${MOUNT_AUTO}" = "TRUE" ];then
		DEV_MOUNT_SUB
	elif [ "${MOUNT_AUTO}" = "FALSE" ];then
		# 実行しない
		:
	fi
}

# バックアップ先デバイスのマウント解除
DEV_UMOUNT() {
	if [ "${MOUNT_AUTO}" = "TRUE" ];then
		DEV_UMOUNT_SUB
	elif [ "${MOUNT_AUTO}" = "FALSE" ];then
		# 実行しない
		:
	fi
}

# スナップショットの作成・マウント・情報取得
SNAP_MOUNT() {
	N=$1
	SNAP_MOUNT_SUB ${N}
}

# スナップショットの情報取得・マウント解除・削除
SNAP_UMOUNT() {
	N=$1
	SNAP_UMOUNT_SUB ${N}
}

# CHECK_LOG の生成
OUTPUT_CHECK_LOG() {
	"${SYSTEM_BACKUP_LOG_CHECK}"
}

# CHECK_LOG の表示
SHOW_CHECK_LOG() {
	echo "-I CHECK_LOG の表示を開始します"
	cat "${SCRIPT_TMP_DIR}/${CHECK_LOG}"
	if [ $? -ne 0 ];then
		echo "-E CHECK_LOG の表示が異常終了しました" 1>&2
		#後続処理を考慮し、ここではexitしない# POST_PROCESS;exit 1
	else
		echo "-I CHECK_LOG の表示が正常終了しました"
		#後続処理を考慮し、ここではexitしない# exit 0
	fi
	echo
}

# DEV_CHECK_LOG の生成
OUTPUT_DEV_CHECK_LOG() {
	if [ "${CHECK_AUTO}" = "TRUE" ];then
		if [ "${MOUNT_TYPE}" = "local" ];then
			# DEV_CHECK_LOG の生成
			"${SYSTEM_BACKUP_DEV_CHECK_LOG_CHECK}" >/dev/null 2>&1
			# DEV_CHECK_LOG の表示
			SHOW_DEV_CHECK_LOG
		elif [ "${MOUNT_TYPE}" = "remote" ];then
			# 実行しない
			:
		fi
	elif [ "${CHECK_AUTO}" = "FALSE" ];then
		# 実行しない
		:
	fi
}

# ログメールの送信
SEND_LOG_MAIL() {
	if [ "${LOG_MAIL}" = "TRUE" ];then
		OUTPUT_LOG_MAIL > "${LOG_MAIL_TMP}"
		cat "${LOG_MAIL_TMP}" | ${DISPCODE2MAIL} | ${SENDMAIL}
		rm -f "${LOG_MAIL_TMP}"
	elif [ "${LOG_MAIL}" = "FALSE" ];then
		# 実行しない
		:
	fi
}

FUNC_FULL() {
	PRE_PROCESS
	SHOW_MENU
	WAIT_START_TIME
	DEV_MOUNT
	DEL_LOG_PREV
	INIT_MAIN_LOG
	SHOW_MSG_JOB_START
	GET_CONFIG_LIST
	DOVECOT_MAINT
	SHOW_DOVECOT_MAINT_LOG
	STOP_RSC
	STOP_SVC
	SNAP_MOUNT 1
	SNAP_MOUNT 2
	START_SVC_SNAP_TRUE
	START_RSC_SNAP_TRUE
	GET_FILE_LIST
	SYSTEM_BACKUP_BACKUP 1
	SYSTEM_BACKUP_BACKUP 2
	SNAP_UMOUNT 2
	SNAP_UMOUNT 1
	DEV_CHECK
	START_SVC_SNAP_FALSE
	START_RSC_SNAP_FALSE
	SHOW_MSG_JOB_END
	OUTPUT_CHECK_LOG
	SHOW_CHECK_LOG
	OUTPUT_DEV_CHECK_LOG
	SEND_LOG_MAIL
	MOVE_LOG_NOW
	DEV_UMOUNT
	POST_PROCESS
}

######################################################################
# 関数定義 (単独実行不可)
######################################################################
USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    system_backup.sh [OPTIONS ...] [START_TIME]
		
		    START_TIME
		       System backup job starts after START_TIME minutes.
		       Specify 0 or a positive integer as START_TIME.
		       If omitted, the default is ${START_TIME}.
		       If the current runlevel is neither of "${MULTI_USER}", START_TIME argument is ignored.
		
		OPTIONS:
		    -y (yes)
		       Suppresses prompting to confirm you want to continue processing
		       this program.
		    -f "FUNC_NAME[,FUNC_NAME...]"
		    --help
		       Display this help and exit.
	EOF
}

# メニューの表示
SHOW_MENU() {
	# YES オプションが指定されていない場合
	if [ "${FLAG_OPT_YES}" = "FALSE" ];then
		# メニューの表示
		echo
		echo "--------------------------------------"
		echo "Operation Mode Selector system_backup"
		echo "--------------------------------------"
		echo
		echo "   1. Continue"
		echo "   2. Cancel"
		echo
		echo "Select operation mode. (Default: ${MENU_DEFAULT})"
		${CHOICE} -c 12 -t ${MENU_DEFAULT},${MENU_TIMEOUT} 2>/dev/null
		# Cancel
		if [ $? -ge 2 ];then POST_PROCESS;exit 0;fi
	fi
}

# 出力ファイル共通ヘッダーの生成
OUTPUT_FILE_HEADER() {
	echo "=============================================================================="
	echo "  This file is automatically created by system backup job."
	echo "=============================================================================="
	echo
}

# サービスの起動 (SUB)
START_SVC_SUB() {
	if [ ! "${SVC_START}" = "" ];then
		if [ "${FLAG_MULTI_USER}" = "TRUE" ];then
			${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "サービスの起動中..."
			"${SVC_START}" > "${SVC_LOG_TMP}" 2>&1
			SVC_RC=$?
			cat "${SVC_LOG_TMP}" | tee -a "${SCRIPT_TMP_DIR}/${MAIN_LOG}"
			rm "${SVC_LOG_TMP}"
			if [ ${SVC_RC} -ne 0 ];then
				${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "サービスの起動が異常終了しました"
				POST_PROCESS;exit 1
			fi
			wall <<- EOF
				Services listed in the following file restarted by system backup job NOW!
				  ${SVC_START}
			EOF
		fi
	fi
}

# サービスの停止 (SUB)
STOP_SVC_SUB() {
	if [ ! "${SVC_STOP}" = "" ];then
		if [ "${FLAG_MULTI_USER}" = "TRUE" ];then
			wall <<- EOF
				Services listed in the following file are going down by system backup job NOW!
				  ${SVC_STOP}
			EOF
			${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "サービスの停止中..."
			"${SVC_STOP}" > "${SVC_LOG_TMP}" 2>&1
			SVC_RC=$?
			cat "${SVC_LOG_TMP}" | tee -a "${SCRIPT_TMP_DIR}/${MAIN_LOG}"
			rm "${SVC_LOG_TMP}"
			if [ ${SVC_RC} -ne 0 ];then
				${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "サービスの停止が異常終了しました"
				POST_PROCESS;exit 1
			fi
		fi
	fi
}

# リソースの起動 (SUB)
START_RSC_SUB() {
	if [ ! "${RSC_START}" = "" ];then
		if [ "${FLAG_MULTI_USER}" = "TRUE" ];then
			${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "リソースの起動中..."
			"${RSC_START}" > "${RSC_LOG_TMP}" 2>&1
			RSC_RC=$?
			cat "${RSC_LOG_TMP}" | tee -a "${SCRIPT_TMP_DIR}/${MAIN_LOG}"
			rm "${RSC_LOG_TMP}"
			if [ ${RSC_RC} -ne 0 ];then
				${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "リソースの起動が異常終了しました"
				POST_PROCESS;exit 1
			fi
			wall <<- EOF
				Resources listed in the following file restarted by system backup job NOW!
				  ${RSC_START}
			EOF
		fi
	fi
}

# リソースの停止 (SUB)
STOP_RSC_SUB() {
	if [ ! "${RSC_STOP}" = "" ];then
		if [ "${FLAG_MULTI_USER}" = "TRUE" ];then
			wall <<- EOF
				Resources listed in the following file are going down by system backup job NOW!
				  ${RSC_STOP}
			EOF
			${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "リソースの停止中..."
			"${RSC_STOP}" > "${RSC_LOG_TMP}" 2>&1
			RSC_RC=$?
			cat "${RSC_LOG_TMP}" | tee -a "${SCRIPT_TMP_DIR}/${MAIN_LOG}"
			rm "${RSC_LOG_TMP}"
			if [ ${RSC_RC} -ne 0 ];then
				${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "リソースの停止が異常終了しました"
				POST_PROCESS;exit 1
			fi
		fi
	fi
}

# バックアップ先デバイスのチェック (SUB)
DEV_CHECK_SUB() {
	${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "バックアップ先デバイスのチェック中..."
	"${SYSTEM_BACKUP_DEV_CHECK}" >/dev/null 2>&1
	#if [ $? -ne 0 ];then DEV_CHECK_SUB;fi
}

# バックアップ先デバイスのマウント (SUB)
DEV_MOUNT_SUB() {
	"${SYSTEM_BACKUP_DEV_MOUNT}"
	if [ $? -ne 0 ];then DEV_MOUNT_SUB;fi
}

# バックアップ先デバイスのマウント解除 (SUB)
DEV_UMOUNT_SUB() {
	"${SYSTEM_BACKUP_DEV_UMOUNT}"
	if [ $? -ne 0 ];then DEV_UMOUNT_SUB;fi
}

# スナップショットの作成・マウント・情報取得 (SUB)
SNAP_MOUNT_SUB() {
	N=$1
	SNAP_FS_LIST_N=SNAP_FS_LIST_${N}
	if [ ! "${!SNAP_FS_LIST_N}" = "" ];then
		SNAP_INFO_BEFORE_LOG_N=SNAP_INFO_BEFORE_LOG_${N}
		${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "スナップショットの作成・マウント・情報取得(${N})の実行中..."
		"${SYSTEM_BACKUP_SNAP_MOUNT}" ${N}
		if [ $? -ne 0 ];then
			${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "スナップショットの作成・マウント・情報取得(${N})が異常終了しました"
			POST_PROCESS;exit 1
		fi
		cat "${SCRIPT_TMP_DIR}/${!SNAP_INFO_BEFORE_LOG_N}" | grep -e "LV Name" -e "%" 2>&1 | tee -a "${SCRIPT_TMP_DIR}/${MAIN_LOG}"
	fi
}

# スナップショットの情報取得・マウント解除・削除 (SUB)
SNAP_UMOUNT_SUB() {
	N=$1
	SNAP_FS_LIST_N=SNAP_FS_LIST_${N}
	if [ ! "${!SNAP_FS_LIST_N}" = "" ];then
		SNAP_INFO_AFTER_LOG_N=SNAP_INFO_AFTER_LOG_${N}
		${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "スナップショットの情報取得・マウント解除・削除(${N})の実行中..."
		"${SYSTEM_BACKUP_SNAP_UMOUNT}" ${N}
		if [ $? -ne 0 ];then
			${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "スナップショットの情報取得・マウント解除・削除(${N})が異常終了しました"
			POST_PROCESS;exit 1
		fi
		cat "${SCRIPT_TMP_DIR}/${!SNAP_INFO_AFTER_LOG_N}" | grep -e "LV Name" -e "%" 2>&1 | tee -a "${SCRIPT_TMP_DIR}/${MAIN_LOG}"
	fi
}

# DEV_CHECK_LOG の表示
SHOW_DEV_CHECK_LOG() {
	echo "-I DEV_CHECK_LOG の表示を開始します"
	cat "${DEV_CHECK_LOG}"
	if [ $? -ne 0 ];then
		echo "-E DEV_CHECK_LOG の表示が異常終了しました" 1>&2
		#後続処理を考慮し、ここではexitしない# POST_PROCESS;exit 1
	else
		echo "-I DEV_CHECK_LOG の表示が正常終了しました"
		#後続処理を考慮し、ここではexitしない# exit 0
	fi
	echo
}

# ログメールの生成
OUTPUT_LOG_MAIL() {
	echo "To: ${LOG_MAIL_RECIPIENT}"
	echo "Subject: ${LOG_MAIL_SUBJECT}"
	echo "Content-Type: text/plain; charset=\"${LOG_MAIL_CHARSET}\""
	echo
	cat "${SCRIPT_TMP_DIR}/${MAIN_LOG}"
	SHOW_CHECK_LOG
	if [ "${CHECK_AUTO}" = "TRUE" ];then
		if [ "${MOUNT_TYPE}" = "local" ];then
			SHOW_DEV_CHECK_LOG
		fi
	fi
}

. yesno_function.sh
. is_numeric_function.sh

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o yf: -l help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE;exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	-y)	FLAG_OPT_YES=TRUE ; shift 1;;
	-f)
		MODE="func"
		FUNC_NAMES="`echo \"$2\" | sed 's/,/ /g'`"
		shift 2
		for func_name in ${FUNC_NAMES} ; do
			case ${func_name} in
PRE_PROCESS|\
POST_PROCESS|\
WAIT_START_TIME|\
DEL_LOG_PREV|\
MOVE_LOG_NOW|\
INIT_MAIN_LOG|\
SHOW_MSG_JOB_START|\
SHOW_MSG_JOB_END|\
START_SVC_SNAP_TRUE|\
START_SVC_SNAP_FALSE|\
STOP_SVC|\
START_RSC_SNAP_TRUE|\
START_RSC_SNAP_FALSE|\
STOP_RSC|\
GET_CONFIG_LIST|\
GET_FILE_LIST|\
DOVECOT_MAINT|\
SHOW_DOVECOT_MAINT_LOG|\
SYSTEM_BACKUP_BACKUP_1|\
SYSTEM_BACKUP_BACKUP_2|\
DEV_CHECK|\
DEV_MOUNT|\
DEV_UMOUNT|\
SNAP_MOUNT_1|\
SNAP_MOUNT_2|\
SNAP_UMOUNT_1|\
SNAP_UMOUNT_2|\
OUTPUT_CHECK_LOG|\
SHOW_CHECK_LOG|\
OUTPUT_DEV_CHECK_LOG|\
SEND_LOG_MAIL|\
FUNC_FULL)
				# 何もしない
				:
				;;
			*)
				echo "-E argument to \"${opt}\" is invalid -- \"${func_name}\"" 1>&2
				USAGE;exit 1
				;;
			esac
		done
		;;
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
	# 指定された文字列が数値か否かのチェック
	IS_NUMERIC "$1"
	if [ $? -ne 0 ];then
		echo "-E 1st argument not numeric -- \"$1\"" 1>&2
		USAGE;exit 1
	fi
	START_TIME=$1
	if [ ! "${FLAG_MULTI_USER}" = "TRUE" ];then
		echo "-W Since the current runlevel is \"${RUNLEVEL}\", START_TIME argument \"${START_TIME}\" is ignored" 1>&2
	fi
fi

if [ "${MODE}" = "full" ];then
	FUNC_FULL
elif [ "${MODE}" = "func" ];then
	for func_name in ${FUNC_NAMES} ; do
		case ${func_name} in
		SYSTEM_BACKUP_BACKUP_1)	SYSTEM_BACKUP_BACKUP 1;;
		SYSTEM_BACKUP_BACKUP_2)	SYSTEM_BACKUP_BACKUP 2;;
		START_SVC_SNAP_TRUE)	START_SVC_SNAP_TRUE;;
		START_SVC_SNAP_FALSE)	START_SVC_SNAP_FALSE;;
		STOP_SVC)	STOP_SVC;;
		SNAP_MOUNT_1)	SNAP_MOUNT 1;;
		SNAP_MOUNT_2)	SNAP_MOUNT 2;;
		SNAP_UMOUNT_1)	SNAP_UMOUNT 1;;
		SNAP_UMOUNT_2)	SNAP_UMOUNT 2;;
		*)	eval ${func_name};;
		esac
	done
fi

