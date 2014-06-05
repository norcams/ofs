#!/bin/bash
yum install -y openstack-nova-compute python-cinderclient openstack-utils openstack-neutron openvswitch openstack-neutron-openvswitch

/usr/bin/openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
/usr/bin/openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname 172.16.188.11

# Configure to use nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver as we use Open vSwitch:
/usr/bin/openstack-config --set /etc/nova/nova.conf DEFAULT libvirt_vif_driver nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver

# Fix iptables
/sbin/iptables -A INPUT -p tcp -m multiport --dports 5900:5999 -j ACCEPT
/sbin/iptables-save > /etc/sysconfig/iptables

# Create symlink
/bin/ln -s /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini /etc/neutron/plugin.ini

# Enable GRE tunneling
/usr/bin/openstack-config --set /etc/neutron/plugin.ini OVS enable_tunneling True
/usr/bin/openstack-config --set /etc/neutron/plugin.ini OVS tenant_network_type gre
/usr/bin/openstack-config --set /etc/neutron/plugin.ini OVS tunnel_id_ranges "1:1000"

# Specify which bridges we use for tunneling
/usr/bin/openstack-config --set /etc/neutron/plugin.ini OVS integration_bridge br-int
/usr/bin/openstack-config --set /etc/neutron/plugin.ini OVS tunnel_bridge br-tun

# Specify IP/network to be used for tunneling (eth2 on each compute node)
/usr/bin/openstack-config --set /etc/neutron/plugin.ini OVS local_ip $(/sbin/ip addr show eth2|grep "inet " |/bin/awk '{ print ($2)}'|/bin/sed 's%/[^/]*$%%')

# Set firewall_driver
openstack-config --set /etc/neutron/plugin.ini \
  securitygroup firewall_driver \
  neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

# Set core plugin to OVS
/usr/bin/openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2

# 
openstack-config --set /etc/nova/nova.conf DEFAULT glance_host 192.168.166.11

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
     DEFAULT neutron_url http://192.168.188.12:9696/
openstack-config --set /etc/nova/nova.conf \
     DEFAULT neutron_admin_tenant_name services
openstack-config --set /etc/nova/nova.conf \
     DEFAULT neutron_admin_username neutron
openstack-config --set /etc/nova/nova.conf \
     DEFAULT neutron_admin_password $NEUTRON_PASS
openstack-config --set /etc/nova/nova.conf \
    DEFAULT neutron_admin_auth_url http://172.16.188.12:35357/v2.0
openstack-config --set /etc/nova/nova.conf \
    DEFAULT security_group_api neutron
openstack-config --set /etc/nova/nova.conf \
    DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

service messagebus start
chkconfig messagebus on
service libvirtd start
chkconfig libvirtd on

service openstack-nova-compute start
chkconfig openstack-nova-compute on

