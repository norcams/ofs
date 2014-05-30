#!/bin/bash
yum install -y openstack-nova-compute python-cinderclient openstack-utils openstack-neutron openvswitch openstack-neutron-openvswitch
/usr/bin/openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
/usr/bin/openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname 172.16.188.11
/sbin/service openvswitch start
/sbin/service chkconfig openvswitch on

# Create internal bridge
/usr/bin/ovs-vsctl add-br br-int

echo "DEVICE=br-int
DEVICETYPE=ovs
TYPE=OVSBridge
ONBOOT=yes
BOOTPROTO=none" >> /etc/sysconfig/network-scripts/ifcfg-br-int

/sbin/service neutron-openvswitch-agent start
/sbin/chkconfig neutron-openvswitch-agent on

/sbin/chkconfig neutron-ovs-cleanup on

# Configure to use nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver as we use Open vSwitch:
/usr/bin/openstack-config --set /etc/nova/nova.conf DEFAULT libvirt_vif_driver nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver

# Fix iptables
/sbin/iptables -A INPUT -p tcp -m multiport --dports 5900:5999 -j ACCEPT
/sbin/iptables-save > /etc/sysconfig/iptables

# Populate DB
su nova -s /bin/sh
/usr/bin/nova-manage db sync
exit

# Start services
#/sbin/service messagebus start
/sbin/chkconfig messagebus on
#/sbin/service libvirtd start
/sbin/chkconfig libvirtd on
#/sbin/service openstack-nova-compute start
/sbin/chkconfig openstack-nova-compute on

# Create symlink
/bin/ln -s /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini /etc/neutron/plugin.ini

# Enable GRE tunneling
/usr/bin/openstack-config --set /etc/neutron/plugin.ini OVS enable_tunneling True
/usr/bin/openstack-config --set /etc/neutron/plugin.ini OVS tenant_network_type gre
/usr/bin/openstack-config --set /etc/neutron/plugin.ini OVS tunnel_id_ranges "1:1000"

# Specify which bridges we use for tunneling
/usr/bin/openstack-config --set /etc/neutron/plugin.ini OVS integration_bridge br-int
/usr/bin/openstack-config --set /etc/neutron/plugin.ini OVS tunnel_bridge br-tun

# Specify IP/network to be use for GRE out (eth0 on each compute node)
/usr/bin/openstack-config --set /etc/neutron/plugin.ini OVS local_ip $(/sbin/ip addr show eth2|grep "inet " |/bin/awk '{ print ($2)}'|/bin/sed 's%/[^/]*$%%')

# Set core plugin to OVS
/usr/bin/openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2

# Create br-tun
/usr/bin/ovs-vsctl add-br br-tun

# 
openstack-config --set /etc/nova/nova.conf DEFAULT glance_host 172.16.188.11
 
