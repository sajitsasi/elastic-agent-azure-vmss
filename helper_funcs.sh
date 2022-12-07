#!/bin/bash

GREEN="\x1B[01;32m"
BLUE="\x1B[01;36m"
RED="\x1B[01;31m"
NOCOL="\x1B[0m"
export AZ_PROT_SETTINGS_FILE="protected-settings.json"
export AZ_PUB_SETTINGS_FILE="public-settings.json"

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

function verify_files() {
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

}
