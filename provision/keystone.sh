#!/bin/bash

yum install -y openstack-keystone openstack-utils openstack-selinux

keystonepw=$(openssl rand -hex 10)
echo "KEYSTONE_DBPASS=$keystonepw" >> ~/passwords.sh

dbpw=$(cat ~/mysql_password)
mysql -u root -p$dbpw -e "CREATE DATABASE keystone CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -p$dbpw -D keystone -e "GRANT ALL ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$keystonepw';"
mysql -u root -p$dbpw -D keystone -e "GRANT ALL ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$keystonepw';"
mysql -u root -p$dbpw -D keystone -e "FLUSH PRIVILEGES;"
mysql -u root -p$dbpw -D keystone -e "SHOW GRANTS FOR 'keystone'@'%';"
mysql -u root -p$dbpw -D keystone -e "SHOW GRANTS FOR 'keystone'@'localhost';"

export SERVICE_TOKEN=$(openssl rand -hex 10)
echo export SERVICE_TOKEN=$SERVICE_TOKEN > ~/keystonerc_token
echo export SERVICE_ENDPOINT="http://172.16.188.11:35357/v2.0" >> ~/keystonerc_token

source ~/passwords.sh

openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $SERVICE_TOKEN
openstack-config --set /etc/keystone/keystone.conf sql connection mysql://keystone:${KEYSTONE_DBPASS}@localhost/keystone
keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
chown -R keystone:keystone /var/log/keystone /etc/keystone/ssl
openstack-config --set /etc/keystone/keystone.conf signing token_format PKI
openstack-config --set /etc/keystone/keystone.conf signing certfile  /etc/keystone/ssl/certs/signing_cert.pem
openstack-config --set /etc/keystone/keystone.conf signing keyfile  /etc/keystone/ssl/private/signing_key.pem
openstack-config --set /etc/keystone/keystone.conf signing ca_certs  /etc/keystone/ssl/certs/ca.pem
openstack-config --set /etc/keystone/keystone.conf signing key_size  1024
openstack-config --set /etc/keystone/keystone.conf signing valid_days  3650
openstack-config --set /etc/keystone/keystone.conf signing ca_password  None
su keystone -s /bin/sh -c "keystone-manage db_sync"
service openstack-keystone start
chkconfig openstack-keystone on

source ~/keystonerc_token
keystone service-create --name=keystone --type=identity --description="Keystone Identity Service"
keystone endpoint-create --service_id $(keystone service-list | awk '/keystone/ { print $2 }') --publicurl 'http://172.16.188.11:5000/v2.0' --adminurl 'http://172.16.188.11:35357/v2.0' --internalurl 'http://172.16.188.11:5000/v2.0'

ADMIN_PASS=$(openssl rand -hex 10)
echo "ADMIN_PASS=$ADMIN_PASS" >> ~/passwords.sh
keystone user-create --name admin --pass $ADMIN_PASS
keystone role-create --name admin
keystone tenant-create --name admin
admin_user_id=$(keystone user-list | awk '/\ admin\ / { print $2 }')
admin_role_id=$(keystone role-list | awk '/\ admin\ / { print $2 }')
admin_tenant_id=$(keystone tenant-list | awk '/\ admin\ / { print $2 }')
keystone user-role-add --user-id $admin_user_id --role-id $admin_role_id --tenant-id $admin_tenant_id

cat << EOF > ~/keystonerc_admin
export OS_USERNAME=admin
export OS_TENANT_NAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://172.16.188.11:5000/v2.0/
export PS1='[\u@\h \W(keystone_admin)]\$ '
EOF

USER_PASS=$(openssl rand -hex 10)
echo "USER_PASS=$USER_PASS" >> ~/passwords.sh
keystone user-create --name user --pass $USER_PASS
keystone role-create --name user
keystone tenant-create --name user
user_user_id=$(keystone user-list | awk '/\ user\ / { print $2 }')
user_role_id=$(keystone role-list | awk '/\ user\ / { print $2 }')
user_tenant_id=$(keystone tenant-list | awk '/\ user\ / { print $2 }')
keystone user-role-add --user-id $user_user_id --role-id $user_role_id --tenant-id $user_tenant_id

cat << EOF > ~/keystonerc_user
export OS_USERNAME=user
export OS_TENANT_NAME=user
export OS_PASSWORD=$USER_PASS
export OS_AUTH_URL=http://172.16.188.11:5000/v2.0/
export PS1='[\u@\h \W(keystone_user)]\$ '
EOF

keystone tenant-create --name services --description "Services Tenant"
