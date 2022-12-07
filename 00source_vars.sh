#!/bin/bash -x

GREEN="\x1B[01;32m"
BLUE="\x1B[01;36m"
RED="\x1B[01;31m"
NOCOL="\x1B[0m"

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
export AZ_PROT_SETTINGS_FILE="protected-settings.json"
export AZ_PUB_SETTINGS_FILE="public-settings.json"

if [ ! -f ./${AZ_PROT_SETTINGS_FILE} ]; then
  echo -e "${RED}ERROR: ${AZ_PROT_SETTINGS_FILE} file not found!!!${NOCOL}"
  echo -e "${RED}ERROR: please create ${AZ_PROT_SETTINGS_FILE} file and place it in $(pwd)${NOCOL}"
  exit -1
else
  if command -v jq &> /dev/null ; then
    ESS_PASS=$(jq -r '.password // empty' ${AZ_PROT_SETTINGS_FILE})
  else
    ESS_PASS=$(grep "\"password\": " ${AZ_PROT_SETTINGS_FILE} | sed -e 's/^[ \t]*//' -e 's/\"//g' | awk '{print $2}')
  fi
  if [ -z "${ESS_PASS}" ]; then
    echo -e "${RED}ERROR: 'password' not found in ${AZ_PROT_SETTINGS_FILE}${NOCOL}"
    echo -e "${RED}ERROR: please add elastic password in ${AZ_PROT_SETTINGS_FILE} ${NOCOL}"
    echo -e "${BLUE}\nFile format:\n\n{\n\t\"password\": \"<elastic_cloud_password>\"\n}\n\n${NOCOL}"
    exit -1
  fi
fi

if [ ! -f ${AZ_PUB_SETTINGS_FILE} ]; then
  echo -e "${RED}ERROR: ${AZ_PUB_SETTINGS_FILE} file not found!!!${NOCOL}"
  echo -e "${RED}ERROR: please create ${AZ_PUB_SETTINGS_FILE} file and place it in $(pwd)${NOCOL}"
  exit -1
else
  if command -v jq &> /dev/null ; then
    ESS_USER=$(jq -r '.username // empty' ${AZ_PUB_SETTINGS_FILE})
    ESS_CLOUD_ID=$(jq -r '.cloudId // empty' ${AZ_PUB_SETTINGS_FILE})
  else
    ESS_USER=$(grep "\"username\": " ${AZ_PUB_SETTINGS_FILE} | sed -e 's/^[ \t]*//' -e 's/\"//g' -e 's/,$//'| awk '{print $2}')
    ESS_CLOUD_ID=$(grep "\"cloudId\": " ${AZ_PUB_SETTINGS_FILE} | sed -e 's/^[ \t]*//' -e 's/\"//g' -e 's/,$//'| awk '{print $2}')
  fi
  if [ -z "${ESS_USER}" ] || [ -z "${ESS_CLOUD_ID}" ]; then
    echo -e "${RED}ERROR: 'username' and/or 'cloudId' not found in ${AZ_PUB_SETTINGS_FILE}${NOCOL}"
    echo -e "${RED}ERROR: please add these values in ${AZ_PUB_SETTINGS_FILE} ${NOCOL}"
    echo -e "${BLUE}\nFile format:\n\n{\n\t\"username\": \"<elastic_cloud_username>\",${NOCOL}"
    echo -e "${BLUE}\t\"cloudId\": \"<elastic_cloud_id_from_deployment_page>\"\n}\n\n${NOCOL}"
    exit -1
  fi
fi


function runcmd() {
  echo -en "${BLUE}+ $@${NOCOL}">&2
  out=$($@ 2>&1)
  if [ $? -eq 0 ]; then
    echo -e "${GREEN} -- success! ${NOCOL}"
  else
    echo -e "\n${RED}${out}${NOCOL}"
    echo "exiting"
    exit -1
  fi
}

function pruncmd() {
  echo -e "${BLUE}+ $@${NOCOL}">&2
  $@ 2>&1
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}command '$@' -- success! ${NOCOL}"
  else
    echo -e "\n${RED}$@ -- FAILED!!!${NOCOL}"
    echo "exiting"
    exit -1
  fi

}

function printcmd() {
  echo -e "${GREEN}$@${NOCOL}"
}
