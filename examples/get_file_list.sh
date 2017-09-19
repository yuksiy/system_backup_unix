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
# ユーザ変数
. "/usr/local/etc/system_backup/env.sh"
if [ $? -ne 0 ];then exit $?;fi

# システム環境 依存変数

# プログラム内部変数
ECHO_LOG="system_backup_echo_log.sh"

FIND_SORT="find_sort.pl"

######################################################################
# メインルーチン
######################################################################

if [ "${SYSTEM_BACKUP_RUN}" = "" ];then exit 0;fi
if [ ! -d "${SCRIPT_TMP_DIR}" ];then exit 0;fi

# ユーザデータファイルリストの取得
export LANG=C
for arg_suffix in ${GET_FILE_LIST_FIND_ARG_SUFFIX} ; do
	arg=`echo ${arg_suffix} | awk -F',' '{print $1}'`
	suffix=`echo ${arg_suffix} | awk -F',' '{print $2}'`
	${ECHO_LOG} "${SCRIPT_TMP_DIR}/${MAIN_LOG}" "ユーザデータファイルリスト(${arg})の取得中..."
	${FIND_SORT} --print0 --exclude="${GET_FILE_LIST_FIND_EXCLUDE}" "${arg}" \
		| xargs -0 -r ls -adl --time-style='+%Y/%m/%d %H:%M:%S' \
		> "${SCRIPT_TMP_DIR}/file_list-${suffix}.log" 2>&1
done

