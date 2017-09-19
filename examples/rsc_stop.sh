#!/bin/sh

DRBD_RSC_STOP() {
	echo "Stopping drbd resource $1"
	/etc/ha.d/resource.d/drbddisk $1 stop
	if [ $? -ne 0 ];then
		exit 1
	fi
}

PM_RSC_STOP() {
	echo "Stopping pacemaker resource $1"
	crm resource stop $1
	if [ $? -ne 0 ];then
		exit 1
	fi
}

PM_RSC_STOP_WAIT() {
	cmd_status_wait.sh "" "crm_resource -WQr $1"
	if [ $? -ne 0 ];then
		exit 1
	fi
}

PM_RSC_STOP      Pacemakerリソースグループ名
PM_RSC_STOP_WAIT Pacemakerリソースグループ中の最初のリソース名
DRBD_RSC_STOP    DRBDリソース名

