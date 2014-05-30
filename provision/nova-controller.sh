#!/bin/bash

yum install -y openstack-nova-api openstack-nova-conductor openstack-nova-scheduler

NOVA_DBPASS=$(openssl rand -hex 10)
echo "NOVA_DBPASS=$NOVA_DBPASS" >> ~/passwords.sh

dbpw=$(cat ~/mysql_password)
mysql -u root -p$dbpw -e "CREATE DATABASE nova CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -p$dbpw -D glance -e "GRANT ALL ON nova.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';"
mysql -u root -p$dbpw -D glance -e "GRANT ALL ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';"
mysql -u root -p$dbpw -D glance -e "FLUSH PRIVILEGES;"
mysql -u root -p$dbpw -D glance -e "SHOW GRANTS FOR 'nova'@'%';"
mysql -u root -p$dbpw -D glance -e "SHOW GRANTS FOR 'nova'@'localhost';"

NOVA_PASS=$(openssl rand -hex 10)
echo "NOVA_PASS=$NOVA_PASS" >> ~/passwords.sh

source ~/keystonerc_token
source ~/passwords.sh
keystone user-create --name nova --pass $NOVA_PASS
keystone user-role-add --user nova --role admin --tenant services
keystone service-create --name nova --type compute --description "OpenStack Compute Service"

keystone endpoint-create --service-id $(keystone service-list | awk '/nova/ { print $2 }') \
    --publicurl "http://192.168.166.11:8774/v2/\$(tenant_id)s" \
    --adminurl "http://172.16.188.11:8774/v2/\$(tenant_id)s" \
    --internalurl "http://172.16.188.11:8774/v2/\$(tenant_id)s"

