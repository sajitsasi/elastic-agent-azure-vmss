#!/bin/bash 

source ./00source_vars.sh
source ./helper_funcs.sh
verify_files

# 1. Create resource group
printcmd "Creating azure resource group ${AZ_RG}"
runcmd "az group create --name ${AZ_RG} --location ${AZ_LOCATION}"

cat << EOF > 99delete_az_resources.sh
#!/bin/bash

az group delete -n ${AZ_RG} -y --no-wait
/bin/rm -f 99delete_az_resources.sh .key .password
EOF
chmod +x 99delete_az_resources.sh

# 2. Create VNET and subnets
printcmd "Creating VNET (${AZ_VNET}) + VMSS subnet (${AZ_VMSS_SUBNET})"
runcmd "az network vnet create \
-g ${AZ_RG} \
-n ${AZ_VNET} \
--address-prefixes ${AZ_VNET_CIDR} \
--subnet-name ${AZ_VMSS_SUBNET} \
--subnet-prefixes ${AZ_VMSS_SUBNET_CIDR} \
--location ${AZ_LOCATION}"

# 3. Create NSG and assign to VMSS subnet
printcmd "Creating NSG ${AZ_NSG_NAME}"
runcmd "az network nsg create -g ${AZ_RG} --name ${AZ_NSG_NAME}"
runcmd "az network nsg rule create \
-g ${AZ_RG} \
--nsg-name ${AZ_NSG_NAME} \
--name AllowSSH \
--direction inbound \
--destination-port-range 22 \
--access allow \
--priority 1000 \
--protocol Tcp"
runcmd "az network vnet subnet update \
-g ${AZ_RG} \
-n ${AZ_VMSS_SUBNET} \
--vnet-name ${AZ_VNET} \
--network-security-group ${AZ_NSG_NAME}"

# 4. Create Public IP for Load Balancer
printcmd "Creating Public IP Address"
runcmd "az network public-ip create \
-g ${AZ_RG} \
--name ${AZ_PUB_IP_NAME} \
--sku standard"

# 5. Create ALB & rules
printcmd "Creating Standard Azure Load Balancer"
runcmd "az network lb create \
-g ${AZ_RG} \
--name ${AZ_SLB} \
--sku standard \
--public-ip-address ${AZ_PUB_IP_NAME} \
--frontend-ip-name ${AZ_LB_FE_NAME} \
--backend-pool-name ${AZ_LB_BE_NAME}"

runcmd "az network lb probe create \
-g ${AZ_RG} \
--lb-name ${AZ_SLB} \
--name SSHHealthProbe \
--protocol tcp \
--port 22"

runcmd "az network lb rule create \
-g ${AZ_RG} \
--lb-name ${AZ_SLB} \
-n SSHtoHost \
--protocol tcp \
--frontend-ip-name ${AZ_LB_FE_NAME} \
--backend-pool-name ${AZ_LB_BE_NAME} \
--frontend-port 22 \
--backend-port 22 \
--disable-outbound-snat true"

# 7. Create Outbound Rule for ALB
printcmd "Creating Outbound rule for ALB"
runcmd "az network lb outbound-rule create \
-g ${AZ_RG} \
--name ${AZ_LB_OB_NAME} \
--lb-name ${AZ_SLB} \
--protocol all \
--address-pool ${AZ_LB_BE_NAME} \
--frontend-ip-configs ${AZ_LB_FE_NAME}"

# 6. Create VMSS
printcmd "Creating VMSS ${AZ_VMSS_CLUSTER}"
runcmd "az vmss create \
-g ${AZ_RG} \
--name ${AZ_VMSS_CLUSTER} \
--instance-count ${AZ_VMSS_COUNT} \
--image UbuntuLTS \
--upgrade-policy automatic \
--admin-username ${USER} \
--admin-password ${AZ_VMSS_PASSWORD} \
--vnet-name ${AZ_VNET} \
--subnet ${AZ_VMSS_SUBNET} \
--load-balancer ${AZ_SLB}"

# 7. Setup Elastic Extension on VMSS
printcmd "Setting up Elastic extension on VMSS"
runcmd "az vmss extension set \
-n ElasticAgent.Linux \
--publisher Elastic \
--version 1.2.0.0 \
--vmss-name ${AZ_VMSS_CLUSTER} \
-g ${AZ_RG} \
--protected-settings ./${AZ_PROT_SETTINGS_FILE} \
--settings ./${AZ_PUB_SETTINGS_FILE}"

# 8. Get Public IP to login to VMSS
AZ_PUB_IP=$(az network public-ip show -g ${AZ_RG} --name ${AZ_PUB_IP_NAME} --query "ipAddress" -o tsv)
echo -e "${BLUE}\nLogin to VMSS using:\nssh ${USER}@${AZ_PUB_IP} with password: ${AZ_VMSS_PASSWORD}"