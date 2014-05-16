#!/bin/bash

yum install -y openstack-glance openstack-utils openstack-selinux

GLANCE_DBPASS=$(openssl rand -hex 10)
echo "GLANCE_DBPASS=$GLANCE_DBPASS" >> ~/passwords.sh

dbpw=$(cat ~/mysql_password)
mysql -u root -p$dbpw -e "CREATE DATABASE glance CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -p$dbpw -D glance -e "GRANT ALL ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';"
mysql -u root -p$dbpw -D glance -e "GRANT ALL ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';"
mysql -u root -p$dbpw -D glance -e "FLUSH PRIVILEGES;"
mysql -u root -p$dbpw -D glance -e "SHOW GRANTS FOR 'glance'@'%';"
mysql -u root -p$dbpw -D glance -e "SHOW GRANTS FOR 'glance'@'localhost';"

GLANCE_PASS=$(openssl rand -hex 10)
echo "GLANCE_PASS=$GLANCE_PASS" >> ~/passwords.sh

source ~/keystonerc_token
source ~/passwords.sh
keystone user-create --name glance --pass $GLANCE_PASS
keystone user-role-add --user glance --role admin --tenant services
keystone service-create --name glance --type image --description "Glance Image Service"
keystone endpoint-create --service-id $(keystone service-list | awk '/glance/ { print $2 }') --publicurl "http://192.168.166.11:9292" --adminurl "http://172.16.188.11:9292" --internalurl "http://172.16.188.11:9292"

openstack-config --set /etc/glance/glance-api.conf DEFAULT sql_connection mysql://glance:${GLANCE_DBPASS}@localhost/glance
openstack-config --set /etc/glance/glance-registry.conf DEFAULT sql_connection mysql://glance:${GLANCE_DBPASS}@localhost/glance
openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_host 172.16.188.11
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_port 5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_tenant_name services
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_user glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken admin_password $GLANCE_PASS
openstack-config --set /etc/glance/glance-registry.conf paste_deploy flavor keystone
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_host 172.16.188.11
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_port 5000
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_tenant_name services
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_user glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken admin_password $GLANCE_PASS
openstack-config --set /etc/glance/glance-api.conf DEFAULT qpid_username glance

mkdir /var/lib/glance/images
chown glance:glance /var/lib/glance/images
restorecon -Rv /var/lib/glance
su glance -s /bin/sh -c "glance-manage db_sync"
service openstack-glance-registry start
service openstack-glance-api start
chkconfig openstack-glance-registry on
chkconfig openstack-glance-api on

