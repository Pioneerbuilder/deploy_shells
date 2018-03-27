#!/usr/bin/env python
from subprocess import call
import paramiko
import shutil
import os
import redis
import time

HOSTS=['10.254.128.119']
jenkins_package=
projectname=
servername=
redis_version=
pass_key=

dir = '/data/%s/uat' % projectname
mkcmd = 'mkdir -p %s' % dir
rmcmd = 'rm -rf %s/*' % dir
if not os.path.exists(dir):
    call(mkcmd, shell=True)
else:
    call(rmcmd, shell=True)

cmd = "cp -r /var/lib/jenkins/workspace/%s/%s/target/%s* /data/%s/uat" %(jenkins_package,projectname,projectname,projectname)
call(cmd, shell=True)


r = redis.Redis(host="localhost", port=6379, db=0)
pre_version = r.get('%s' % redis_version)
if not pre_version:
    pre_version = '100'
cur_version = str(int(pre_version)+1)
cur_version_str = '.'.join(cur_version)

print'cur_version_str:%s'%cur_version_str

print '***************** pre_version of redis is %s *****************' % pre_version

root_pass = r.get('%s' % pass_key)


try:
    for host in HOSTS:
        cmd='rsync -vzrtopg --progress --delete /data/%s/uat/%s/ jenkins@%s:/home/jenkins/%s/' % (projectname,projectname,host,projectname)
        call(cmd, shell=True)
        time.sleep(5)
        
    print '***************** restart tomcat... *****************'

    for host in HOSTS:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=host, username='root', port=22, password="%s" % root_pass)
        ssh.exec_command('mkdir -p /projects/%s/%s' % (projectname,cur_version_str))
        time.sleep(1)
        ssh.exec_command('mv /home/jenkins/%s/* /projects/%s/%s/ && chown -R root:root /projects/%s/%s' % (projectname,projectname,cur_version_str,projectname,cur_version_str))
        time.sleep(1)
        NULL,stdout,errout = ssh.exec_command('export JAVA_HOME=/usr/java/jdk1.7.0_80 && /data/%s/bin/shutdown.sh' % servername)
        stopFlag =False
        for value in stdout:
            if 'Tomcat stopped' in value :
                stopFlag =True
                print 'Tomcat stopped successfully'
                break
        if not stopFlag:
            flag =True
            for i in range(10):
                if not flag:
                    print 'stop-force successfully'
                    break
                else:
                    NULL,stdout,errout =ssh.exec_command('export JAVA_HOME=/usr/java/jdk1.7.0_80 && /data/%s/bin/shutdown.sh' % servername)
                    for value in stdout:
                        if 'Killing Tomcat with the PID' in value :
                            flag =False
                            print 'stop-force:%s' %value
                            break
                        if '$CATALINA_PID was set but the specified file does not exist. Is Tomcat running? Stop aborted' in value :
                            flag =False
                            print 'tomcat already shutdown!'
                            break
                    print 'start to sleep for shutdown'
                    #time.sleep(6)
                    print 'end sleep for shutdown'

        print time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()))
        time.sleep(1)
        ssh.exec_command('rm -rf  /data/%s/webapps/%s && ln -s /projects/%s/%s /data/%s/webapps/%s' % (servername,projectname,projectname,cur_version_str,servername,projectname))
        print time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()))
        time.sleep(1)
        print time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()))
        ssh.exec_command('export JAVA_HOME=/usr/java/jdk1.7.0_80 && /data/%s/bin/startup.sh' % servername)
        print time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()))
        
        print '***************** sleep 15S for tomcat startup on%s *****************' %host
        time.sleep(15)
        print '***************** end sleep for tomcat startup on%s *****************' %host
        
        ssh.close()
        
    print '***************** reset chunbo_rwms_order_dubbo_version of redis by %s *****************' % cur_version_str

    r.set('%s' % redis_version ,cur_version)

except Exception, ex:
    print ex
