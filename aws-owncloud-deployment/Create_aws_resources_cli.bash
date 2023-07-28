#!/usr/bin/env bash

#create a VPC
gl_vpc=$(aws ec2 create-vpc \
     --cidr-block 10.0.0.0/16 \
	--query Vpc.VpcId \
	--output text \
    --tag-specification "ResourceType=vpc,Tags=[{Key=Name,Value=gl-vpc}]")

#create public subnet 
gl_pub_subnet=$(aws ec2 create-subnet \
    --vpc-id $gl_vpc \
	--availability-zone us-east-1a \
    --cidr-block 10.0.1.0/24 \
	--query Subnet.SubnetId \
	--output text \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=gl-pub-subnet}]")

aws ec2 modify-subnet-attribute --subnet-id $gl_pub_subnet --map-public-ip-on-launch 
 
#create private subnet 
gl_pri_subnet=$(aws ec2 create-subnet \
    --vpc-id $gl_vpc \
	--availability-zone us-east-1a \
    --cidr-block 10.0.2.0/24 \
	--query Subnet.SubnetId \
	--output text \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=gl-pri-subnet}]")
	


gl_gateway=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId \
  --output text --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=gl-gateway}]")
  
  
aws ec2 attach-internet-gateway --vpc-id $gl_vpc --internet-gateway-id $gl_gateway

gl_rt_gateway=$(aws ec2 create-route-table --vpc-id $gl_vpc --query RouteTable.RouteTableId --output text \
   --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=gl-rt-gateway}]")

#create an entry to route the  0.0.0.0/0 traffic to the gateway 
aws ec2 create-route --route-table-id $gl_rt_gateway --destination-cidr-block 0.0.0.0/0 --gateway-id $gl_gateway  

#print the routes 
aws ec2 describe-route-tables --route-table-id $gl_rt_gateway 

#print the subnets in vpc
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$gl_vpc" --query "Subnets[*].{ID:SubnetId,CIDR:CidrBlock}"

#associate the gl_rt_gateway to public subnet
aws ec2 associate-route-table  --subnet-id $gl_pub_subnet --route-table-id $gl_rt_gateway   

#Modify the subnet atttribute to assign public IP address for resources placed in subnet 
aws ec2 modify-subnet-attribute --subnet-id $gl_pub_subnet --map-public-ip-on-launch

#create a keypair
gl_keypair="gl-keypair"
aws ec2 create-key-pair --key-name $gl_keypair --query "KeyMaterial" --output text > $gl_keypair.pem

chmod 400 $gl_keypair

#create a security group for public subnet resources 
gl_pub_sg=$(aws ec2 create-security-group --group-name gl-pub-sg --description "Security group for SSH access" \
	--vpc-id $gl_vpc \
    --query GroupId --output text)

#authorize the security group for ssh access
aws ec2 authorize-security-group-ingress --group-id $gl_pub_sg --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $gl_pub_sg --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $gl_pub_sg --protocol tcp --port 443 --cidr 0.0.0.0/0


gl_pri_sg=$(aws ec2 create-security-group --group-name gl-pri-sg --description "Security group for SSH & MYSQL access from public subnet" \
	--vpc-id $gl_vpc \
    --query GroupId --output text)
	
aws ec2 authorize-security-group-ingress --group-id $gl_pri_sg --protocol tcp --port 22 --cidr 10.0.1.0/24
aws ec2 authorize-security-group-ingress --group-id $gl_pri_sg --protocol tcp --port 3306 --cidr 10.0.1.0/24

#create an EC2 instance on the public subnet
#ami-08fdec01f5df9998f  ubuntu 18.04 on t2.micro 

ubuntu_18_04="ami-08fdec01f5df9998f"

gl_app_server=$(aws ec2 run-instances --image-id $ubuntu_18_04 --count 1 --instance-type t2.micro --key-name $gl_keypair \
 --security-group-ids $gl_pub_sg \
 --subnet-id $gl_pub_subnet \
 --associate-public-ip-address \
 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=gl-app-server}]' \
 --query Instances[0].InstanceId \
 --output text)
 
 #get the public IP address 
 gl_app_server_ip=$(aws ec2 describe-instances --instance-id $gl_app_server \
 --query Reservations[0].Instances[0].PublicIpAddress \
 --output text)
 
 #create ec2 instance for db-server in private network 
  
 gl_db_server=$(aws ec2 run-instances --image-id $ubuntu_18_04 --count 1 --instance-type t2.micro --key-name $gl_keypair \
 --security-group-ids $gl_pri_sg \
 --subnet-id $gl_pri_subnet \
 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=gl-db-server}]' \
 --query Instances[0].InstanceId \
 --output text)
 
 #allocate Elastic IP address
 gl_nat_elastic_ip=$(aws ec2 allocate-address --query AllocationId --output text)
 
 #create NAT gateway on the public subnet with an Elastic IP 
 
 gl_nat_gw=$(aws ec2 create-nat-gateway \
    --subnet-id $gl_pub_subnet \
    --allocation-id $gl_nat_elastic_ip \
	--query NatGateway.NatGatewayId \
	--output text)
 
 #create route table for private subnet 
 gl_rt_pri=$(aws ec2 create-route-table --vpc-id $gl_vpc --query RouteTable.RouteTableId --output text \
   --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=gl-rt-pri}]")
 
 #create an entry to route the  0.0.0.0/0 traffic to the nat gateway 
aws ec2 create-route --route-table-id $gl_rt_pri --destination-cidr-block 0.0.0.0/0 --gateway-id $gl_nat_gw  
 
 #assoicate 
 aws ec2 associate-route-table  --subnet-id $gl_pri_subnet --route-table-id $gl_rt_pri  
 
 #copy the keypair file to app server 
 scp -i ${gl_keypair}.pem ${gl_keypair}.pem ubuntu@$gl_app_server_ip:.ssh 
 
 
 

 
 
 