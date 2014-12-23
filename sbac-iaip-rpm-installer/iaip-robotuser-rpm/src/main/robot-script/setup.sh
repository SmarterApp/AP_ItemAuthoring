#!/bin/sh
echo 'removing user robot if exists'
/usr/sbin/userdel -r robot
echo 'adding user robot'
/usr/sbin/adduser -d /home/robot -m robot
echo 'move to robot home directory'
cd /home/robot
echo 'make ssh directory'
mkdir .ssh
echo 'change permissions of ssh directory to 700'
chmod 700 .ssh
echo 'change owner of ssh directory to robot'
chown robot.robot .ssh
echo 'write shared key to authorized_keys'
echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVwLK/b7MP9WRAeN5f8WdCD2BeFGjBseHap7eWeF2d9xNDXczAraqIyev89scItL9pnV79/59KnYSHkYe8r5h/11OhN+40TzkXHJqc9SRrfU7J0tt3aRVR6IGUbGDRXaYmxyOCIHoShwkQWT7BjH3LaYMtVDOqSFXA3cohq+vTuhexjWNT/ne7dUfAu8hZgqSxxeLNLZE6q/g/mQipfmozmDK8EUarcoV0dFyojFLr+MYCbh5d4nnTzfe8rcynKI+SeUmckMc8aJwS1O1MHt2+laI979F9RfF9FeJtglY74zqwhWLAmXXU6IS/U+G50g1W15QG0npQl28KMnEZbXU7 robot@sbacuat.pacificmetrics.com >> .ssh/authorized_keys


echo 'change permissions on authorized_keys'
chmod 640 .ssh/authorized_keys
echo 'change owner of authorized_keys to robot'
chown robot.robot .ssh/authorized_keys
echo 'update sudoers file allowing robot to run commands without a password'
echo 'robot  ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

### When run from inside RPM it will provide 'python-simplejson' for us
### echo 'installing latest version of python simplejson'
### yum install python-simplejson

exit

