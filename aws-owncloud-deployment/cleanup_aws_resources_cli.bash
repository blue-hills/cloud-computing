#!/usr/bin/env bash
 
 #CLEANUP 
 
 #terminate the instance both app & db servers
 aws ec2 terminate-instances --instance-ids $gl_app_server
 aws ec2 terminate-instances --instance-ids $gl_db_server
 
 #delete NAT gateway
 aws ec2 delete-nat-gateway --nat-gateway-id $gl_nat_gw 
 
 
 #delete security groups
 aws ec2 delete-security-group --group-id $gl_pub_sg
 aws ec2 delete-security-group --group-id $gl_pri_sg
 
 #delete subnets
 aws ec2 delete-subnet --subnet-id $gl_pub_subnet
 aws ec2 delete-subnet --subnet-id $gl_pri_subnet
 
 #delete EC2 route tables 
 aws ec2 delete-route-table --route-table-id $gl_rt_gateway
 aws ec2 delete-route-table --route-table-id $gl_rt_pri
 
 #detach internet-gateway
 aws ec2 detach-internet-gateway --internet-gateway-id $gl_gateway --vpc-id $gl_vpc
 
 #delete internet-gateway
 aws ec2 delete-internet-gateway --internet-gateway-id $gl_gateway
 
 #delete vpc
 aws ec2 delete-vpc --vpc-id $gl_vpc
 
 #release address
 aws ec2 release-address --allocation-id $gl_nat_elastic_ip
 
 
 
 
 
 
 
 