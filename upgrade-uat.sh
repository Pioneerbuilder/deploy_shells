#!/bin/sh

## change here
SERVICE_DIR=/projects/chunbo-dps-web/
SERVICE_NAME=chunbo-dps-web
SERVER_NAME=springboot-dps-web
LOGGING_PATH=/data/${SERVER_NAME}/dpslog
LOGGING_FILE=dps.log

JAVA_OPTS="-server -Xms400m -Xmx400m -Xmn300m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=128m -Xverify:none -XX:+DisableExplicitGC -Djava.awt.headless=true"

this_dir="$( cd "$( dirname "$0"  )" && pwd )"
parent_dir=`dirname "${this_dir}"`
log_dir="${parent_dir}/dpslog"
log_file="${log_dir}/nohup.out"
#jar_file="${parent_dir}/apps/${jar_name}"


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
			#echo "spring.profiles.active=${SPRING_PROFILES_ACTIVE}"
			#echo "nohup ${JRE_HOME}/bin/java -Xms128m -Xmx512m -jar ${SERVICE_DIR}${VERSION}/${SERVICE_NAME}\.jar --server.port=${SERVER_PORT} --logging.path=${LOGGING_PATH} --logging.file=${LOGGING_FILE} >/dev/null 2>&1 &"
			#exec nohup ${JRE_HOME}/bin/java -Xms128m -Xmx512m -jar ${SERVICE_DIR}${VERSION}/${SERVICE_NAME}\.jar --server.port=${SERVER_PORT} --logging.path=${LOGGING_PATH} --logging.file=${LOGGING_FILE} >/dev/null 2>&1 &
			exec nohup ${JRE_HOME}/bin/java $JAVA_OPTS -jar ${SERVICE_DIR}${VERSION}/${SERVICE_NAME}\.jar --server.port=${SERVER_PORT} >"${log_file}" &
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

