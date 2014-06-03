#!/bin/bash

service openvswitch start
chkconfig openvswitch on

ovs-vsctl add-br br-tun
ovs-vsctl add-br br-int

cat > /etc/sysconfig/network-scripts/ifcfg-br-int <<EOF 
DEVICE=br-int
DEVICETYPE=ovs
TYPE=OVSBridge
ONBOOT=yes
BOOTPROTO=none
EOF

service neutron-openvswitch-agent start
chkconfig neutron-openvswitch-agent on
chkconfig neutron-ovs-cleanup on

 
