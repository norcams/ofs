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
    # Share passwords via vagrant folder
    cp ~/keystonerc_* ~/passwords.sh /vagrant/
    ;;
  network)
    /vagrant/provision/neutron-network.sh
    /vagrant/provision/openvswitch-network.sh
    /vagrant/provision/l3-agent.sh
    ;;
esac

