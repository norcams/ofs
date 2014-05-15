#!/bin/bash
yum install -y qpid-cpp-server qpid-cpp-server-ssl
perl -p -i -e 's/auth=yes/auth=no/' /etc/qpidd.conf
service qpidd start
chkconfig qpidd on

