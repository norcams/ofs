#!/bin/bash

role=$(hostname -s)

# All
/vagrant/provision/repo.sh

# Role
case $role in
  controller)
    /vagrant/provision/mysql.sh
    /vagrant/provision/qpid.sh
    /vagrant/provision/keystone.sh
    /vagrant/provision/glance.sh
    /vagrant/provision/neutron-controller.sh
    /vagrant/provision/nova-controller.sh
    /vagrant/provision/nova-common.sh
    /vagrant/provision/nova-controller-startup.sh
    # Share passwords via vagrant folder
    cp ~/keystonerc_* ~/passwords.sh /vagrant/
    ;;
  network)
    /vagrant/provision/neutron-network.sh
    /vagrant/provision/openvswitch-network.sh
    /vagrant/provision/l3-agent.sh
    ;;
  compute)
    /vagrant/provision/nova-compute.sh
    /vagrant/provision/nova-common.sh
    /vagrant/provision/nova-compute-startup.sh
esac

