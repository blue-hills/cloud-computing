#!/bin/bash 
yum update -y
amazon-linux-extras install -y docker
systemctl enable docker
usermod -aG docker ec2-user

yum install awscli -y 

docker run --name db-docker --restart always -e MYSQL_ROOT_PASSWORD="bluehills" -d -p 3306:3306 506160996768.dkr.ecr.us-east-1.amazonaws.com/project2-dbserver:latest

cat << EOM > /var/lib/cloud/scripts/per-boot/copy_db_config
#!/bin/bash
public_ip=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "DB_HOST=\$public_ip" > /tmp/db-server.env
echo "DB_USER=root" >> /tmp/db-server.env
echo "DB_PASSWORD=bluehills" >> /tmp/db-server.env
echo "DB_DATABASE=user" >> /tmp/db-server.env
echo "TEST=user" >> /tmp/db-server.env
aws s3 cp /tmp/db-server.env s3://balagurusamy
EOM

chmod +x /var/lib/cloud/scripts/per-boot/copy_db_config
/var/lib/cloud/scripts/per-boot/copy_db_config

