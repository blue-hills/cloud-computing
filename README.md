# [Post Graduate program in Cloud Computing, UT-Austin](http://www.mccombs.utexas.edu/execed/for-individuals/certificates/great-learning/#d.en.30507)
##  Completed Course projects 

###  [OwnCloud Deployment in AWS](https://github.com/blue-hills/cloud-computing/tree/main/aws-owncloud-deployment)
* Use of Internet Gateways and Route Tables to create public subnets to host Web Severs.
* Use of NAT Gateways and Route tables to create private subnets to host Database Servers
* Use of Stateful Security groups to allow  access to SSH/HTTP/MySQL in EC2 instances
* Bastion host to SSH access the Database servers in private subnets
* Deployment of LAMP stacks on Linux EC2 instances
* Implementation of AWS CLI scripts to create configure different AWS services
![f1](https://github.com/blue-hills/cloud-computing/assets/50052802/3427920f-29d4-4de9-9713-5eeeaa2ab0d7)


### [Deployment of PHP Data Entry Application Docker Containers in FARGATE/ECS](https://github.com/blue-hills/cloud-computing/tree/main/aws-ecs-fargate-containers)

* Use of ECS in Serverless FARGATE environment.
* Use of Load balancer to distribute the load across multiple Docker Containers.
* Implementation of MySQL and PHP Docker Containers for a Simple Data Entry Application
* Deployment of PHP Docker Container in ECS/FARGATE using Code Pipeline.
* Deployment of MySQL Docker Containers in EC2 instances
![project2-architecture](https://github.com/blue-hills/cloud-computing/assets/50052802/a0562d93-32f9-41ec-a147-fea39bc1c51b)


### [Deployment of AWS Open Search Domain to search PDF documents using Lambdas](https://github.com/blue-hills/cloud-computing/tree/main/aws-opensearch-lambdas)
* Use of S3 Trigger Lambda functions to parse and upload the PDF Documents to the AWS Open Search Engine 
* Use of AWS Gateway REST API Lambdas to query the Open Search Engine
* Use of Boto3 Python library to create code pipelines and IAM roles 
* Use of SAM CloudFormation templates to deploy Lambdas using the AWS Code Pipelines
![Workflow using Lambda Triggers](https://github.com/blue-hills/cloud-computing/assets/50052802/b9a2f250-c0d4-42bb-8d3b-2376177d6dcc)
![LambdaPipellines](https://github.com/blue-hills/cloud-computing/assets/50052802/01051443-4382-40fe-bad0-8673b44dd99b)

  
###  [Deployment of MatterMost in Azure](https://github.com/blue-hills/cloud-computing/tree/main/az-mattermost-deployment)
* Use of NSG rules and VNET to create public subnet to host the internet facing MatterMost servers
* Use of NIC and public IP address to access the MatterMost servers 
* Use of NSG rules and VNET to create private subnet to host MySQL servers and to deny the access from internet
* Use of AZ CLI to create VMS to run MatterMost and MySQL servers.
  ![MatterMostDeployment](https://github.com/blue-hills/cloud-computing/assets/50052802/5abc3e45-82ba-4a88-bf6b-50e3dc4967b3)

### [Deployment of Application Gateway, Traffic Manager, Load Balancers, VM Scale Sets, Flexible MySQL Sever database and App Service](https://github.com/blue-hills/cloud-computing/tree/main/az-appgw-tm-vmss-loadbal-appsvc)

#### This project demonstrates the use of various Azure resources in implementing the following key software design patterns and ideas.

|   |   |
|---|---|
|Strangler Fig Pattern |Use of Application Gateway for gradual migration from legacy systems to modern systems based on Path based Rules|
|Canary Releases|Use of Traffic manager for canary releases based on weighted Routing method|
|Elasticity|VM scale sets to scale out/in based on loads/performance metrics|
|Load Balancer|Use of Public load balancer with Traffic Manager. Use of both Public & Private load balancer in Application Gateway. Session Affinity/persistence.|
|Serverless Deployment|Use of Git Hub workflow to deploy a PHP Web Application on App Service Plan.|
|Lift And Shift Cases|Use of VM Scale sets with appropriate OS and runtime binaries to run the legacy applications|

![architecture2](https://github.com/blue-hills/cloud-computing/assets/50052802/6516f90b-6246-4b1f-9746-b13984825c17)
