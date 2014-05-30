#!/bin/bash
yum install -y openstack-nova-compute python-cinderclient openstack-utils openstack-neutron
/usr/bin/openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
/usr/bin/openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname 172.16.188.11

