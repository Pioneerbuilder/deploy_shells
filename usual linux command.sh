nohup /usr/java/jdk1.8.0_162/bin/java -jar chunbo-dps-web.jar > nohup.out 2>&1 &


nohup /usr/java/jdk1.8.0_162/bin/java -jar chunbo-dps-web.jar --server.port=8088 > nohup.out 2>&1 &


ps -ef | grep -w "chunbo-dps-web" |grep -w "java"| grep -v "grep"


export VERSION=1.0.6 && export SERVER_PORT=8088 && /data/springboot-dps-web/bin/upgrade.sh restart

ln -s /projects/chunbo-dps-web/1.1.8/chunbo-dps-web.jar /data/springboot-dps-web/chunbo-dps-web



netstat -ntulp |grep 80