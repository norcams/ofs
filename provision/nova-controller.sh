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
    --internalurl "http://192.168.166.11:8774/v2/\$(tenant_id)s" \
    --adminurl "http://172.16.188.11:8774/v2/\$(tenant_id)s"
 
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/api-paste.ini filter:authtoken auth_host 192.168.166.11
openstack-config --set /etc/nova/api-paste.ini filter:authtoken admin_tenant_name services
openstack-config --set /etc/nova/api-paste.ini filter:authtoken admin_user nova
openstack-config --set /etc/nova/api-paste.ini filter:authtoken admin_password $NOVA_PASS

# mysql
openstack-config --set /etc/nova/nova.conf DEFAULT sql_connection \
    mysql://nova:${NOVA_DBPASS}@172.16.188.11/nova

# qpid
openstack-config --set /etc/nova/nova.conf \
     DEFAULT rpc_backend nova.openstack.common.rpc.impl_qpid
openstack-config --set /etc/nova/nova.conf \
     DEFAULT qpid_hostname 172.16.188.11

# neutron
openstack-config --set /etc/nova/nova.conf \
     DEFAULT network_api_class nova.network.neutronv2.api.API
openstack-config --set /etc/nova/nova.conf \
     DEFAULT neutron_url http://192.168.166.11:9696/
openstack-config --set /etc/nova/nova.conf \
     DEFAULT neutron_admin_tenant_name services
openstack-config --set /etc/nova/nova.conf \
     DEFAULT neutron_admin_username neutron
openstack-config --set /etc/nova/nova.conf \
     DEFAULT neutron_admin_password $NEUTRON_PASS
openstack-config --set /etc/nova/nova.conf \
    DEFAULT neutron_admin_auth_url http://172.16.188.11:35357/v2.0
openstack-config --set /etc/nova/nova.conf \
    DEFAULT security_group_api neutron
openstack-config --set /etc/nova/nova.conf \
    DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

nova-manage db sync

service openstack-nova-api start
chkconfig openstack-nova-api on
service openstack-nova-scheduler start
chkconfig openstack-nova-scheduler on
service openstack-nova-conductor start
chkconfig openstack-nova-conductor on

