#!/bin/bash

nova-manage db sync

service openstack-nova-api start
chkconfig openstack-nova-api on
service openstack-nova-scheduler start
chkconfig openstack-nova-scheduler on
service openstack-nova-conductor start
chkconfig openstack-nova-conductor on

