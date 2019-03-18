#!/bin/bash

if ! mount | grep vdb 1> /dev/null ; then mount -t iso9660 -o ro /dev/sr0 /mnt; fi
source /mnt/context.sh

# drop firewall
iptables -F
iptables -X
systemctl stop firewalld
systemctl mask firewalld

# install salt repository
yum -y install ${SALT_REPO_PACKAGE}

# install salt master
yum -y install salt-minion

# set salt master ip
echo "master: ${SALT_MASTER_PRIVATE_IP_ADDRESS}" >> /etc/salt/minion
# set salt minion id
echo "id: ${USER_TOKEN}-${VMID}" >> /etc/salt/minion

# enable salt minion service
systemctl enable salt-minion
