#!/bin/bash
 
openstack-config --set /etc/neutron/metadata_agent.ini \
   DEFAULT auth_strategy keystone

openstack-config --set /etc/neutron/metadata_agent.ini \
   keystone_authtoken auth_host 192.168.166.11

openstack-config --set /etc/neutron/metadata_agent.ini \
   keystone_authtoken admin_tenant_name services

openstack-config --set /etc/neutron/metadata_agent.ini \
   keystone_authtoken admin_user neutron

source /vagrant/passwords.sh
openstack-config --set /etc/neutron/metadata_agent.ini \
   keystone_authtoken admin_password $NEUTRON_PASS

openstack-config --set /etc/neutron/l3_agent.ini \
   DEFAULT interface_driver \
   neutron.agent.linux.interface.OVSInterfaceDriver

openstack-config --set /etc/neutron/l3_agent.ini \
   DEFAULT external_network_bridge br-ex

