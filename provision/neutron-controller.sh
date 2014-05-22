#!/bin/bash

NEUTRON_DBPASS=$(openssl rand -hex 10)
echo "NEUTRON_DBPASS=$NEUTRON_DBPASS" >> ~/passwords.sh

dbpw=$(cat ~/mysql_password)
mysql -u root -p$dbpw -e "CREATE DATABASE ovs_neutron CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -p$dbpw -D glance -e "GRANT ALL ON ovs_neutron.* TO 'neutron'@'%' IDENTIFIED BY '$NEUTRON_DBPASS';"
mysql -u root -p$dbpw -D glance -e "GRANT ALL ON ovs_neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS';"
mysql -u root -p$dbpw -D glance -e "FLUSH PRIVILEGES;"
mysql -u root -p$dbpw -D glance -e "SHOW GRANTS FOR 'neutron'@'%';"
mysql -u root -p$dbpw -D glance -e "SHOW GRANTS FOR 'neutron'@'localhost';"

NEUTRON_PASS=$(openssl rand -hex 10)
echo "NEUTRON_PASS=$NEUTRON_PASS" >> ~/passwords.sh

source ~/keystonerc_token
source ~/passwords.sh
keystone user-create --name neutron --pass $NEUTRON_PASS
keystone user-role-add --user neutron --role admin --tenant services
keystone service-create --name neutron --type network --description "OpenStack Networking Service"
keystone endpoint-create --service-id $(keystone service-list | awk '/neutron/ { print $2 }') --publicurl "http://192.168.166.12:9696" --adminurl "http://172.16.188.12:9696" --internalurl "http://172.16.199.12:9696"

# Set innodb as default storage engine for mysql
yum -y install augeas
augtool set '/files/etc/my.cnf/target[. = "mysqld"]/default-storage-engine' innodb

