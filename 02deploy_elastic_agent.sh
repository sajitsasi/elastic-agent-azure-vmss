#!/bin/bash

source ./helper_funcs.sh
verify_files

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
