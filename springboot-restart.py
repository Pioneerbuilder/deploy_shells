#!/usr/bin/env python
from subprocess import call
import paramiko
import shutil
import os
import redis
import time


HOSTS=['10.254.128.126']
jenkins_package='chunbo-dps-web-uat-deploy'
projectname='chunbo-dps-web'
servername='springboot-dps-web'
server_port='8088'
redis_version='chunbo_dps_web_uat_version'
pass_key='root_pass_uat'

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
        cmd='rsync -vzrtopg --progress --delete /data/%s/uat/ jenkins@%s:/home/jenkins/%s/' % (projectname,host,projectname)
        call(cmd, shell=True)
        time.sleep(5)

    for host in HOSTS:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=host, username='root', port=22, password="%s" % root_pass)
        
        
             
        ssh.exec_command('mkdir -p /projects/%s/%s' % (projectname,cur_version_str))
        time.sleep(1)
        ssh.exec_command('mv /home/jenkins/%s/* /projects/%s/%s/ && chown -R root:root /projects/%s/%s' % (projectname,projectname,cur_version_str,projectname,cur_version_str))
        time.sleep(1)
        #ssh.exec_command('rm -rf  /data/%s/webapps/%s && ln -s /projects/%s/%s /data/%s/webapps/%s' % (servername,projectname,projectname,cur_version_str,servername,projectname))
        time.sleep(1)
        
        print 'restart %s %s' %(host,servername)
        print 'export VERSION=%s && export SERVER_PORT=%s && /data/%s/bin/upgrade.sh restart' % (cur_version_str, server_port, servername)
        
        NULL,stdout,errout =ssh.exec_command('export VERSION=%s && export SERVER_PORT=%s && /data/%s/bin/upgrade.sh restart' % (cur_version_str, server_port, servername))
        for value in stdout:
            print '%s %s' % (host,value)
        
        print '***************** sleep 15S for tomcat startup on%s *****************' %host
        #time.sleep(30)
        
        ssh.close()
        
    print '***************** reset %s_uat of redis by %s *****************' % (projectname, cur_version_str)

    r.set('%s' % redis_version ,cur_version)

except Exception, ex:
    print ex