#!/bin/sh

SVC_START() {
	#echo "Starting $1"
	/etc/init.d/$1 start
	if [ $? -ne 0 ];then
		exit 1
	fi
}

SVC_START サービス名

