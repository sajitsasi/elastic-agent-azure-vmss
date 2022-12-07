#!/bin/bash 

if [ -f ./.key ]; then
    KEY=$(cat .key)
else
    KEY=${RANDOM}
    echo -n ${KEY} > .key
fi

if [ -f ./.password ]; then
    AZ_VMSS_PASSWORD=$(cat .password)
else
    AZ_VMSS_PASSWORD=$(LC_CTYPE=C tr -cd '[:alnum:]' < /dev/urandom | fold -w16 | head -n1)
    echo -n ${AZ_VMSS_PASSWORD} > .password
fi


DIR=$(pwd)
export AZ=$(which az)
export AZ_LOCATION="eastus"
export AZ_RG="${USER}-es-vmss-rg"
export AZ_VMSS_SUBNET="es-vmss-subnet"
export AZ_VM_SUBNET="vm-subnet"
export AZ_PE_SUBNET="pe-subnet"
export AZ_VNET="es-vmss-vnet"
export AZ_VNET_CIDR="10.125.0.0/16"
export AZ_VMSS_CLUSTER="es-vmss-${KEY}"
export AZ_VMSS_COUNT=3
export AZ_VMSS_SUBNET_CIDR="10.125.0.0/20"
export AZ_VM_SUBNET_CIDR="10.125.16.0/24"
export AZ_PE_SUBNET_CIDR="10.125.18.0/24"
export ES_MASTER_COUNT=3
export AZ_NODE_PASSWORD=""
export AZ_NSG_NAME="es-vmss-nsg"
export AZ_PUB_IP_NAME="es-vmss-public-ip"
export AZ_SLB="es-vmss-pub-lb"
export AZ_LB_FE_NAME="es-vmss-fe"
export AZ_LB_BE_NAME="es-vmss-be"
export AZ_LB_OB_NAME="InternetOutboundRule"
