#!/bin/bash

sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

systemctl restart sshd.service

#sudo mkdir /root/.ssh


# FOR PG_INSTALL TESTING
#yum install -y git > /dev/null 2>&1
#git clone https://github.com/lalbrekht/pg_install.git /root/pg_install
