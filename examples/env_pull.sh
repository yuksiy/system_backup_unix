#!/bin/bash

# 下記のサンプル定義で想定しているサーバのホスト名と用途は
# 以下のファイルのヘッダー部分を参照してください。
#   /usr/local/etc/remote_maint_common_conf.sh

# ユーザ変数
. /usr/local/sbin/remote_maint_common.sh

LOG_ROOT="/BKUP/LOG"

unset RSYNC_LOG_1
unset RSYNC_LOG_2
i=1 ; for host_group in ${HOST_GROUPS} ; do
	case ${host_1[${i}]} in
	dns1,dns2)
		RSYNC_LOG_1[${i}]="rsync_1.log"
		RSYNC_LOG_2[${i}]="rsync_2.log"
		;;
	mail1,mail2)
		RSYNC_LOG_1[${i}]="rsync_1.log"
		RSYNC_LOG_2[${i}]="rsync_2.log"
		;;
	www1,www2)
		RSYNC_LOG_1[${i}]="rsync_1.log"
		RSYNC_LOG_2[${i}]="rsync_2.log"
		;;
	samba)
		RSYNC_LOG_1[${i}]="rsync_1.log"
		;;
	esac
	i=`expr ${i} + 1`
done

