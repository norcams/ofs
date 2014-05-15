#!/bin/bash
yum install -y mysql-server
service mysqld start
chkconfig mysqld on
dbpw=$(openssl rand -hex 10)
echo $dbpw > ~/mysql_password
/usr/bin/mysqladmin -u root password "$dbpw"

