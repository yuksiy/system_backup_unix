#!/bin/sh

SVC_STOP() {
	#echo "Stopping $1"
	/etc/init.d/$1 stop
	if [ $? -ne 0 ];then
		exit 1
	fi
}

SVC_STOP サービス名

