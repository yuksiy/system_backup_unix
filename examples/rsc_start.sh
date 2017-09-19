#!/bin/sh

DRBD_RSC_START() {
	echo "Starting drbd resource $1"
	/etc/ha.d/resource.d/drbddisk $1 start
	if [ $? -ne 0 ];then
		exit 1
	fi
}

PM_RSC_START() {
	echo "Starting pacemaker resource $1"
	crm resource start $1
	if [ $? -ne 0 ];then
		exit 1
	fi
}

PM_RSC_START_WAIT() {
	cmd_status_wait.sh "${HOSTNAME}" "crm_resource -WQr $1"
	if [ $? -ne 0 ];then
		exit 1
	fi
}

DRBD_RSC_START    DRBDリソース名
PM_RSC_START      Pacemakerリソースグループ名
PM_RSC_START_WAIT Pacemakerリソースグループ中の最後のリソース名

