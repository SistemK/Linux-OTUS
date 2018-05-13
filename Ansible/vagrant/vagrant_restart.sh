#!/bin/bash

# Delete running hosts 
vagrant destroy -f host0 host1
VBoxManage unregistervm --delete host0
VBoxManage unregistervm --delete host1
#VBoxManage unregistervm --delete host2
rm -rf $HOME/VirtualBox\ VMs/host*
rm -rf /tmp/disk2_*

# Up hosts
vagrant up host0 host1 

# Copy ssh keys to hosts
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "192.168.33.10"
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "192.168.33.11"
#ssh-keygen -f "$HOME/.ssh/known_hosts" -R "192.168.33.12"
sshpass -f $HOME/Dropbox/bin/Ansible/vagrant/password.txt -v ssh-copy-id -o StrictHostKeyChecking=no root@192.168.33.10
sshpass -f $HOME/Dropbox/bin/Ansible/vagrant/password.txt -v ssh-copy-id -o StrictHostKeyChecking=no root@192.168.33.11
#sshpass -f $HOME/Dropbox/bin/Ansible/vagrant/password.txt -v ssh-copy-id -o StrictHostKeyChecking=no root@192.168.33.12
