#!/bin/bash
yum install -y mysql-server augeas
# Set innodb as default storage engine for mysql
augtool set '/files/etc/my.cnf/target[. = "mysqld"]/default-table-type' innodb
service mysqld start
chkconfig mysqld on
dbpw=$(openssl rand -hex 10)
echo $dbpw > ~/mysql_password
/usr/bin/mysqladmin -u root password "$dbpw"

