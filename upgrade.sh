#!/bin/sh

## change here
SERVICE_NAME=chunbo-dps-web
SERVICE_DIR=/projects/${SERVICE_NAME}

JAVA_OPTS="-Xms400m -Xmx400m -Xmn300m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=128m -Xverify:none -XX:+DisableExplicitGC -Djava.awt.headless=true"
SPRING_BOOT_OPTS=" --server.port=${SERVER_PORT} --logging.file=../dpslog/dps-web.log"

this_dir="$( cd "$( dirname "$0"  )" && pwd )"
parent_dir=`dirname "${this_dir}"`
log_dir="${parent_dir}/dpslog"
log_file="${log_dir}/nohup.out"

## java env
export JAVA_HOME=/usr/java/jdk1.8.0_162
export JRE_HOME=${JAVA_HOME}/jre

if [ ! -d "${log_dir}" ]; then
    mkdir "${log_dir}"
fi

case "$1" in 
	start)
		procedure=`ps -ef | grep -w "${SERVICE_NAME}" |grep -w "java"| grep -v "grep" | awk '{print $2}'`
		if [ "${procedure}" = "" ];
		then
			echo "start ..."
			if [ "$2" != "" ];
			then
				SPRING_PROFILES_ACTIVE=$2
			fi
			exec nohup ${JRE_HOME}/bin/java $JAVA_OPTS -jar ${SERVICE_DIR}/${VERSION}/${SERVICE_NAME}\.jar ${SPRING_BOOT_OPTS} >"${log_file}" &
			start_flag=`ps -ef | grep -w "${SERVICE_NAME}" |grep -w "java"| grep -v "grep" | awk '{print $2}'`
			if [ "${start_flag}" != "" ];
			then
				echo "start ${SERVICE_NAME} success"
			else
				echo "start ${SERVICE_NAME} not success"
			fi
		else
			echo "${SERVICE_NAME} is start"
		fi
		;;
		
	stop)
		procedure=`ps -ef | grep -w "${SERVICE_NAME}" |grep -w "java"| grep -v "grep" | awk '{print $2}'`
		if [ "${procedure}" = "" ];
		then
			echo "${SERVICE_NAME} is stop"
		else
			kill ${procedure}
			sleep 5
			argprocedure=`ps -ef | grep -w "${SERVICE_NAME}" |grep -w "java"| grep -v "grep" | awk '{print $2}'`
			if [ "${argprocedure}" = "" ];
			then
				echo "${SERVICE_NAME} stop success"
			else
				kill -9 ${argprocedure}
				echo "${SERVICE_NAME} stop-force"
			fi
		fi
		;;
		
	restart)
		$0 stop
		sleep 1
		$0 start $2
		;;  
		
	*)
		echo "usage: $0 [start|stop|restart] [dev|test|prod]"
		;;  
esac

