#!/bin/bash

source /vagrant/passwords.sh

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
    DEFAULT neutron_admin_auth_url http://192.168.166.11:35357/v2.0
openstack-config --set /etc/nova/nova.conf \
    DEFAULT security_group_api neutron
openstack-config --set /etc/nova/nova.conf \
    DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

ln -sf /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
    /etc/neutron/plugin.ini
openstack-config --set /etc/neutron/plugin.ini \
    securitygroup firewall_driver \
    neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

