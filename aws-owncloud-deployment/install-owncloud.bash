#!/usr/bin/env bash
#run this script as follows
#dbserver_ip=xxxxx install-owncloud.bash 

if  [$dbserver_ip = ""] ;
then 
echo "exiting now. dbserver_ip is not defined";
exit;
fi

sec_admin_pwd="pi=3.14159"
echo $sec_admin_pwd > /etc/.sec_admin_pwd.txt

sec_db_pwd="pi=3.14159"
echo $sec_db_pwd > /etc/.sec_db_pwd.txt

FILE="/usr/local/bin/occ"

cat <<EOM >$FILE
#! /bin/bash
cd /var/www/owncloud
sudo -E -u www-data /usr/bin/php /var/www/owncloud/occ "\$@"
EOM

chmod +x $FILE

echo "Created the helper file: $FILE"

cd /var/www/
wget https://download.owncloud.com/server/stable/owncloud-complete-latest.tar.bz2 && \
tar -xjf owncloud-complete-latest.tar.bz2 && \
chown -R www-data. owncloud

echo "Downloaded the OwnCloud repo" 

  occ maintenance:install \
    --database "mysql" \
	--database-host ${dbserver_ip} \
    --database-name "owncloud" \
    --database-user "owncloud" \
    --database-pass ${sec_db_pwd} \
    --data-dir "/var/www/owncloud/data" \
    --admin-user "admin" \
    --admin-pass ${sec_admin_pwd}

app_server_ip=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
local_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
client_ip=$(echo $SSH_CLIENT | awk '{ print $1}')

occ config:system:set trusted_domains 1 --value="$client_ip"
occ config:system:set trusted_domains 2 --value="$app_server_ip"
occ config:system:set trusted_domains 3 --value="$local_ip"

occ config:system:set files_external_allow_create_new_local --value 'true'

occ background:cron
echo "*/15  *  *  *  * /var/www/owncloud/occ system:cron" \
  | sudo -u www-data -g crontab tee -a \
  /var/spool/cron/crontabs/www-data
  
echo "0  2  *  *  * /var/www/owncloud/occ dav:cleanup-chunks" \
  | sudo -u www-data -g crontab tee -a \
  /var/spool/cron/crontabs/www-data  

echo "Configuring Memcache\APCu"  
  
occ config:system:set \
   memcache.local \
   --value '\OC\Memcache\APCu'
   
   echo "Configuring Memcache\Redis"
occ config:system:set \
   memcache.locking \
   --value '\OC\Memcache\Redis'
occ config:system:set \
   redis \
   --value '{"host": "127.0.0.1", "port": "6379"}' \
   --type json

FILE="/etc/logrotate.d/owncloud"
cat <<EOM >$FILE
/var/www/owncloud/data/owncloud.log {
  size 10M
  rotate 12
  copytruncate
  missingok
  compress
  compresscmd /bin/gzip
}
EOM

cd /var/www/
chown -R www-data. owncloud

systemctl restart apache2
echo "apache2 has been restarted"

occ -V
echo "Your Admin password is: "$sec_admin_pwd
echo "It's documented at /etc/.sec_admin_pwd.txt"
echo "Your Database Password is: "$sec_db_pwd
echo "It's documented at /etc/.sec_db_pwd.txt and in your config.php"
echo "Your ownCloud is accessable under: "$my_domain
echo "The Installation is complete."
   