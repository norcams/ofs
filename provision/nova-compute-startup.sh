#!/bin/bash

service messagebus start
chkconfig messagebus on
service libvirtd start
chkconfig libvirtd on

service openstack-nova-compute start
chkconfig openstack-nova-compute on

