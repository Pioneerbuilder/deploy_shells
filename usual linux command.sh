nohup /usr/java/jdk1.8.0_162/bin/java -jar xxx\.jar --server.port=8088 > nohup.out 2>&1 &

ps -ef | grep -w "xxx" | grep -w "java"| grep -v "grep"

netstat -ntulp |grep 80

vim ~/.bashrc
source ~/.bashrc

git branch | grep test | xargs git push origin --delete