#!/bin/bash

yum install -y augeas openstack-neutron \
   openstack-neutron-openvswitch \
   openstack-utils \
   openstack-selinux

iptables -A INPUT -p tcp -m multiport --dports 9696 -j ACCEPT
iptables-save > /etc/sysconfig/iptables

augtool set '/files/etc/sysctl.conf/net.ipv4.ip_forward' 1
sysctl -e -p

source /vagrant/passwords.sh
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_host 172.16.188.11
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name services
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_user neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_password $NEUTRON_PASS

openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname 172.16.188.11

ln -s /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini \
    /etc/neutron/plugin.ini

openstack-config --set /etc/neutron/plugin.ini \
  OVS enable_tunneling True
openstack-config --set /etc/neutron/plugin.ini \
  OVS tenant_network_type gre
openstack-config --set /etc/neutron/plugin.ini \
  OVS tunnel_id_ranges "1:1000"

openstack-config --set /etc/neutron/plugin.ini \
  OVS integration_bridge br-int
openstack-config --set /etc/neutron/plugin.ini \
  OVS tunnel_bridge br-tun

openstack-config --set /etc/neutron/plugin.ini \
  OVS local_ip 172.16.199.12

openstack-config --set /etc/neutron/neutron.conf \
  DEFAULT core_plugin \
  neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2

openstack-config --set /etc/neutron/plugin.ini \
   DATABASE sql_connection \
   mysql://neutron:$NEUTRON_DBPASS@172.16.188.11/ovs_neutron

neutron-db-manage \
   --config-file /usr/share/neutron/neutron-dist.conf \
   --config-file /etc/neutron/neutron.conf \
   --config-file /etc/neutron/plugin.ini stamp icehouse

service neutron-server start
chkconfig neutron-server on

source /vagrant/passwords.sh
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/dhcp_agent.ini keystone_authtoken auth_host 172.16.188.11
openstack-config --set /etc/neutron/dhcp_agent.ini keystone_authtoken admin_tenant_name services
openstack-config --set /etc/neutron/dhcp_agent.ini keystone_authtoken admin_user neutron
openstack-config --set /etc/neutron/dhcp_agent.ini keystone_authtoken admin_password $NEUTRON_PASS

openstack-config --set /etc/neutron/dhcp_agent.ini \
    DEFAULT interface_driver \
    neutron.agent.linux.interface.OVSInterfaceDriver

service neutron-dhcp-agent start
chkconfig neutron-dhcp-agent on

