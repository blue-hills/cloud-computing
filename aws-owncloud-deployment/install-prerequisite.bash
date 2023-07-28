#!/usr/bin/env bash

apt update && apt upgrade -y

add-apt-repository ppa:ondrej/php -y
apt update && apt upgrade -y

apt install -y \
  apache2 \
  libapache2-mod-php7.4 \
  openssl redis-server wget \
  php7.4 php7.4-imagick php7.4-common php7.4-curl \
  php7.4-gd php7.4-imap php7.4-intl php7.4-json \
  php7.4-mbstring php7.4-gmp php7.4-bcmath php7.4-mysql \
  php7.4-ssh2 php7.4-xml php7.4-zip php7.4-apcu \
  php7.4-redis php7.4-ldap php-phpseclib
  
  
apt-get install -y php7.4-smbclient
echo "extension=smbclient.so" > /etc/php/7.4/mods-available/smbclient.ini
phpenmod smbclient
systemctl restart apache2  

apt install -y \
  unzip bzip2 rsync curl jq \
  inetutils-ping  ldap-utils\
  smbclient
  
php -m | grep smbclient  

#install mysql-client 
apt-get install -y mysql-client
  
