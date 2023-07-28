#!/usr/bin/env bash

apt update && apt upgrade -y
apt install -y mysql-server
 
sed -i "/\[mysqld\]/atransaction-isolation = READ-COMMITTED\nperformance_schema = on" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s/bind-address/#bind-address/" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "/\[mysqld\]/abind-address = 0.0.0.0" /etc/mysql/mysql.conf.d/mysqld.cnf

systemctl start mysql.service 
mysql -u root -e "CREATE DATABASE IF NOT EXISTS owncloud; \
  CREATE USER 'owncloud'@'localhost' IDENTIFIED BY 'pi=3.14159';  \
  GRANT ALL PRIVILEGES ON *.* TO 'owncloud'@'localhost' WITH GRANT OPTION; \
  FLUSH PRIVILEGES; \
  CREATE USER 'owncloud'@'%' IDENTIFIED BY 'pi=3.14159'; \
  GRANT ALL PRIVILEGES ON *.* TO 'owncloud'@'%' WITH GRANT OPTION; \
  FLUSH PRIVILEGES; "  
