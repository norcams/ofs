#!/bin/bash -vx
neutron net-create --router:external=True floatingnet
neutron subnet-create \
  --name floatingsubnet \
  --allocation-pool start=192.168.177.20,end=192.168.177.29 \
  --gateway 192.168.177.11 \
  --enable_dhcp=False \
  floatingnet 192.168.177.0/24

