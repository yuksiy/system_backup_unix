#!/bin/sh

# ユーザ変数
export HOSTNAME=`hostname`

export MENU_DEFAULT=1
export MENU_TIMEOUT=10

export MOUNT_TYPE="local"
export MOUNT_AUTO="TRUE"
export CHECK_AUTO="FALSE"

export BKUP_DEV_1="/dev/sdb1"
export BKUP_DEV_FS_1="ext4"
export BKUP_MNT_1="/BKUP"
export BKUP_MNT_OPT_1="-o noatime"
export BKUP_UMNT_OPT_1="-f"
export BKUP_CHK_OPT_1="-f -a -v -C"
export BKUP_MOUNT_LOG_1="/var/log/mount-`basename ${BKUP_DEV_1}`.log"
export BKUP_UMOUNT_LOG_1="/var/log/umount-`basename ${BKUP_DEV_1}`.log"
export BKUP_CHECK_LOG_1="/var/log/fsck-`basename ${BKUP_DEV_1}`.log"

export BKUP_DEV_2=""
export BKUP_DEV_FS_2=""
export BKUP_MNT_2=""
export BKUP_MNT_OPT_2=""
export BKUP_UMNT_OPT_2=""
export BKUP_CHK_OPT_2=""
export BKUP_MOUNT_LOG_2=""
export BKUP_UMOUNT_LOG_2=""
export BKUP_CHECK_LOG_2=""

export LOG_ROOT="${BKUP_MNT_1}/LOG"
export LOG_DIR="${LOG_ROOT}/${HOSTNAME}"

export DEST_ROOT="${BKUP_MNT_1}/DAT"
export DEST_DIR="${DEST_ROOT}/${HOSTNAME}"

export MAIN_LOG="@main.log"
export CHECK_LOG="@check.log"
export DEV_CHECK_LOG="/var/log/fsck-check.log"

export RSYNC_LOG_1="rsync_1.log"

export RSYNC_LOG_2=""

export SVC_START="/usr/local/etc/system_backup/svc_start.sh"
export SVC_STOP="/usr/local/etc/system_backup/svc_stop.sh"

export RSC_START=""
export RSC_STOP=""

export SNAP_USE="TRUE"

export SNAP_ROOT_1="/SNAP"
export SNAP_FS_LIST_1="/usr/local/etc/system_backup/snapshot_list_1.txt"
export SNAP_MOUNT_LOG_1="snap_mount_1.log"
export SNAP_INFO_BEFORE_LOG_1="snap_info_before_1.log"
export SNAP_INFO_AFTER_LOG_1="snap_info_after_1.log"
export SNAP_UMOUNT_LOG_1="snap_umount_1.log"

export SNAP_ROOT_2=""
export SNAP_FS_LIST_2=""
export SNAP_MOUNT_LOG_2=""
export SNAP_INFO_BEFORE_LOG_2=""
export SNAP_INFO_AFTER_LOG_2=""
export SNAP_UMOUNT_LOG_2=""

export DOVECOT_MAINT_LOG=""

export GET_FILE_LIST_FIND_ARG_SUFFIX="/,ROOT"
export GET_FILE_LIST_FIND_EXCLUDE="^(?:\
/proc/[0-9]+\\z\
${BKUP_MNT_1:+|${BKUP_MNT_1}/}${BKUP_MNT_2:+|${BKUP_MNT_2}/}\
${LOG_ROOT:+|${LOG_ROOT}/}${DEST_ROOT:+|${DEST_ROOT}/}\
${SNAP_ROOT_1:+|${SNAP_ROOT_1}/}${SNAP_ROOT_2:+|${SNAP_ROOT_2}/}\
)"

export LOG_MAIL="FALSE"
export LOG_MAIL_RECIPIENT="root"
export LOG_MAIL_SUBJECT="system_backup ${HOSTNAME}"
export LOG_MAIL_CHARSET="ISO-2022-JP"
export DISPCODE2MAIL="iconv -f UTF-8 -t ISO-2022-JP"
export SENDMAIL="sendmail -oi -t"

