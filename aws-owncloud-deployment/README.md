## Deployment of OwnCloud Server in AWS
* Use of Internet Gateways and Route Tables to create public subnets to host Web Severs.
* Use of NAT Gateways and Route tables to create private subnets to host Database Servers
* Use of Stateful Security groups to allow  access to SSH/HTTP/MySQL in EC2 instances
* Bastion host to SSH access the Database servers in private subnets
* Deployment of LAMP stacks on Linux EC2 instances
* Implementation of AWS CLI scripts to create configure different AWS services
![Architecture](./architecture.svg]