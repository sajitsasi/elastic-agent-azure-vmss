#!/bin/bash

export AZ_PROT_SETTINGS_FILE="protected-settings.json"
export AZ_PUB_SETTINGS_FILE="public-settings.json"
GREEN="\x1B[01;32m"
BLUE="\x1B[01;36m"
RED="\x1B[01;31m"
NOCOL="\x1B[0m"

function printcmd() {
  echo -e "${GREEN}$@${NOCOL}"
}

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

function usage() {
  echo -e "${RED}usage: $0 -g <azure_resource_group> -v <vmss_cluster_name>${NOCOL}"
  exit -1
}

while getopts g:v: args
do 
    case "${args}" in 
        g) 
          AZ_RG=${OPTARG}
          echo -e "${BLUE} using resource group ${AZ_RG}${NOCOL}"
          ;;
        v) 
          AZ_VMSS_CLUSTER=${OPTARG}
          echo -e "${BLUE} using resource group ${AZ_VMSS_CLUSTER}${NOCOL}"
          ;;
        *)
          usage
    esac 
done 

if [ -z "${AZ_RG}" ] || [ -z "${AZ_VMSS_CLUSTER}" ]; then
  echo -e "${RED}ERROR: either resource group and/or VMSS cluster name not provided${NOCOL}"
  usage
fi

printcmd "Setting up Elastic extension on VMSS"
runcmd "az vmss extension set \
-n ElasticAgent.Linux \
--publisher Elastic \
--version 1.2.0.0 \
--vmss-name ${AZ_VMSS_CLUSTER} \
-g ${AZ_RG} \
--protected-settings ./${AZ_PROT_SETTINGS_FILE} \
--settings ./${AZ_PUB_SETTINGS_FILE}"
