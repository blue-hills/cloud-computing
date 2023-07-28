#!/usr/bin/env bash
LOCATION="eastus"
RES_GROUP="RGMatterMost"
VNET="VNetMatterMost"
CIDR_VNET="10.0.0.0/16"

IMAGE_VM="Ubuntu2204"
VM_SIZE="Standard_B2s"
USER_VM="azureuser"
SSH_KEY="SshKeyMatterMost"
SSH_KEY_FILE="mattermost-vm-key"

NSG_APP_SERVER="NsgAppServer"
SUBNET_APP_SERVER="SubentAppServer"
CIDR_APP_SERVER="10.0.0.0/24"
IP_APP_SERVER="IPAppServer"
NIC_APP_SERVER="NICAppServer"
VM_APP_SERVER="VMAppServer"


NSG_DB_SERVER="NsgDbServer"
SUBNET_DB_SERVER="SubentDBServer"
CIDR_DB_SERVER="10.0.1.0/24"
VM_DB_SERVER="VMDbServer"

#Create a resource group (RGMatterMost) for the MatterMost project
az  group create --location ${LOCATION} --name ${RES_GROUP} 

#create VNET for the mattermost project
az network vnet create --resource-group ${RES_GROUP} --name ${VNET} \
      --address-prefixes ${CIDR_VNET}  --location ${LOCATION} --no-wait false 

echo "Provisioned a vnet with CIDR ${CIDR_VNET}"

#Create a subnet for AppServer  
az network vnet subnet create --resource-group ${RES_GROUP} --name ${SUBNET_APP_SERVER} --vnet-name ${VNET}\
      --address-prefixes ${CIDR_APP_SERVER} --no-wait false 

echo "Provisioned a subnet for AppServer with CIDR ${CIDR_APP_SERVER} "

#Create a subnet for DBSERVER  
az network vnet subnet create --resource-group ${RES_GROUP} --name ${SUBNET_DB_SERVER} --vnet-name ${VNET}\
      --address-prefixes ${CIDR_DB_SERVER} --no-wait false 

echo "Provisioned a subnet for DBSERVER with CIDR ${CIDR_DB_SERVER} "


#create a NSG for APP-SERVER (MatterMost)
az network nsg create --location ${LOCATION} --name ${NSG_APP_SERVER} \
--resource-group ${RES_GROUP} --no-wait false 

echo "Created an NSG for AppServer ${NSG_APP_SERVER}"
#Add NSG rules for ssh port 
az network nsg rule create --name AllowSSH --nsg-name ${NSG_APP_SERVER} --resource-group ${RES_GROUP} \
    --access Allow --priority 150 --source-address-prefix Internet --source-port-range "*" \
    --destination-address-prefix "*" --destination-port-ranges 22 --direction Inbound \
    --protocol Tcp --no-wait false --description "Allow ssh ports"

echo "Created an NSG inbound rule for ssh in ${NSG_APP_SERVER}"

#Add NSG rules for MatterMost Port
az network nsg rule create --name AllowMatterMost --nsg-name ${NSG_APP_SERVER} --resource-group ${RES_GROUP} \
    --access Allow --priority 200 --source-address-prefix Internet --source-port-range "*" \
    --destination-address-prefix "*" --destination-port-ranges 8065 --direction Inbound \
    --protocol Tcp --no-wait false --description "Allow MatterMost ports"

echo "Created an NSG inbound rule for port 8065 in ${NSG_APP_SERVER}"


#associate the NSG with the subnet
az network vnet subnet update --vnet-name ${VNET} --name ${SUBNET_APP_SERVER} \
 --resource-group ${RES_GROUP} --network-security-group ${NSG_APP_SERVER} --no-wait false 

echo "Associated the NSG ${NSG_APP_SERVER} with the subnet : ${SUBNET_APP_SERVER}"



#Create a NSG for DB-SERVER (MySQL)
az network nsg create --location ${LOCATION} --name ${NSG_DB_SERVER} \
--resource-group ${RES_GROUP} --no-wait false 
echo "Created a NSG : ${NSG_DB_SERVER}"

#Add NSG rule to allow MySQL connections (port 3306) from APPSERVER subnet to DBSERVER subnet
az network nsg rule create --resource-group ${RES_GROUP} --nsg-name ${NSG_DB_SERVER} \
    --name AllowMySqlFromAppSubnet --no-wait false \
    --access Allow --protocol Tcp --direction Inbound --priority 150 \
    --source-address-prefix ${CIDR_APP_SERVER} --source-port-range "*" \
    --destination-address-prefix "*" --destination-port-range 3306  

echo "Created an NSG rule to allow MySQL connections from APPSERVER subnet: ${CIDR_APP_SERVER} to DBSERVER subnet: ${CIDR_DB_SERVER} "

#Add a NSG rule to allow SSH connections (port 22) from APPSERVER subnet to DBSERVER subnet
az network nsg rule create --resource-group ${RES_GROUP} --nsg-name ${NSG_DB_SERVER} \
    --name AllowSSHFromAppSubnet --no-wait false \
    --access Allow --protocol Tcp --direction Inbound --priority 200 \
    --source-address-prefix ${CIDR_APP_SERVER} --source-port-range "*" \
    --destination-address-prefix "*" --destination-port-range 22 

echo "Created an NSG rule to allow SSH connections from APPSERVER subnet: ${CIDR_APP_SERVER} to DBSERVER subnet: ${CIDR_DB_SERVER} "

# Create an NSG rule to block all outbound traffic from the DBSERVER subnet
az network nsg rule create --resource-group ${RES_GROUP} --nsg-name ${NSG_DB_SERVER} \
--name DenyInternet --access Deny --protocol Tcp --direction Outbound --priority 300 \
--source-address-prefix "*" --source-port-range "*" \
--destination-address-prefix "*" --destination-port-range "*" --no-wait false 

#associate NSG_DB_SERVER with the subnet SUBNET_DB_SERVER
az network vnet subnet update --vnet-name ${VNET} \
--name ${SUBNET_DB_SERVER} --resource-group ${RES_GROUP} \
 --network-security-group ${NSG_DB_SERVER} --no-wait false 

echo "Associated the NSG ${NSG_DB_SERVER} with the subnet : ${SUBNET_DB_SERVER}"


#create a public IP for MatterMost server
az network public-ip create --resource-group ${RES_GROUP} --name ${IP_APP_SERVER} \
--allocation-method Static --version IPv4  
echo "Created a public IP address : ${IP_APP_SERVER}  for MatterMost server"


#create an NIC for MatterMost Server
az network nic create --resource-group ${RES_GROUP} --name ${NIC_APP_SERVER} \
--vnet-name ${VNET} --subnet ${SUBNET_APP_SERVER}\
 --network-security-group ${NSG_APP_SERVER} --public-ip-address ${IP_APP_SERVER} \
 --no-wait false

echo "Created an NIC ${NIC_APP_SERVER} for MatterMostServer "


#Generate an SSH key using ssh-keygen and copy the public key to Azure Resource group
ssh-keygen -t rsa -b 4096 -f ${SSH_KEY_FILE}

#Copy the public key to resource grouop 
az sshkey create --name ${SSH_KEY} --public-key "@./mattermost-vm-key.pub" \
--resource-group ${RES_GROUP}

#create a VM for Mattermost server with the NIC 
az vm create --resource-group ${RES_GROUP} --name ${VM_APP_SERVER} \
--image ${IMAGE_VM} --size ${VM_SIZE} --nics ${NIC_APP_SERVER}  \
--vnet-name ${VNET} --subnet ${SUBNET_DB_SERVER} \
--admin-username ${USER_VM} --ssh-key-name ${SSH_KEY}  \
 --public-ip-sku "BASIC"  

echo "Created a ${VM_SIZE} ${IMAGE_VM} vm for MatterMost app server with ssh-key ${SSH_KEY}"

#create a VM for MYSQL server with the NIC 
az vm create --resource-group ${RES_GROUP} --name ${VM_DB_SERVER}  \
--public-ip-address '""' \
--image ${IMAGE_VM} --size ${VM_SIZE} \
--admin-username ${USER_VM} --ssh-key-name ${SSH_KEY}  \
--vnet-name ${VNET} --subnet ${SUBNET_DB_SERVER}


echo "Created a ${VM_SIZE} ${IMAGE_VM} vm for MySQL DB server with ssh-key ${SSH_KEY}"


#get the public IP address of the App server

APP_SERVER_IP=$(az network public-ip list --resource-group ${RES_GROUP} --query [].ipAddress --output tsv)

#Copy the SSH key to App Server using scp command 
#SSH key will enable us to establish ssh connection to DB server from App Server
scp -i ${SSH_KEY_FILE}  ${SSH_KEY_FILE}  azureuser@${APP_SERVER_IP}:.ssh 


#Add a NSG rule to allow SSH connections (port 22) from APPSERVER subnet to DBSERVER subnet
az network nsg rule create --resource-group ${RES_GROUP} \
    --nsg-name ${NSG_DB_SERVER} --no-wait false \
    --name DenyInternet --priority 250 \
    --access Deny --protocol Tcp --direction Outbound  \
    --source-address-prefix "*" --source-port-range "*" \
    --destination-address-prefix "*" --destination-port-range "*" 