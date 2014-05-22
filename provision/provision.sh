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
    cp ~/keystonerc_* ~/passwords.sh /vagrant/
    ;;
esac

