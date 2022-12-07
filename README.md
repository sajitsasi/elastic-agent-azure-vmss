# Elastic Agent on an Azure VM Scale Set

## Introduction
Elastic provides a unified observability solution for your entire Azure ecosystem.  The scripts in this repo will deploy an Azure VM Scale Set (VMSS) and its associated required components (VNET, Load Balancer, Public IP etc.). After the VMSS has been deployed, it will install the Elastic Agent to send metrics data to your managed Elasticsearch cluster running in any of the 3 cloud providers (AWS, Azure, GCP).  
  
Follow instructions in [Deploy VMSS & Elastic Agent to VMSS cluster](#deploy-all-azure-resources-and-elastic-agent) to deploy full set of resources.  
Follow instructions in [Deploy Elastic Agent to existing VMSS Cluster](#deploy-elastic-agent-to-already-existing-vmss) to deploy Elastic Agent to an already existing VMSS cluster

## Pre-requisistes
  ### Deploy Elasticsearch cluster
  * Deploy a managed Elasticsearch cluster in the cloud provider of your choice. More details can be found [here](https://www.elastic.co/guide/en/cloud/current/ec-getting-started.html) on how you can get a free cloud trial if you don't already have a subscription
  * [Create an Elastic Cloud deployment](https://www.elastic.co/guide/en/cloud/current/ec-create-deployment.html) and save your credentials as that will be needed later
  * Go to [cloud.elastic.co](https://cloud.elastic.co) and choose the gear right next to the newly created deployment.
  * Once in the deployment view page, copy the **Cloud ID** value and save it.
  ### Create configuration files
  * Clone this repository: ```git clone https://github.com/sajitsasi/elastic-agent-azure-vmss.git```
  * Change directory to repo location: ```cd elastic-agent-azure-vmss/```
  * Create a file named ```public-settings.json``` with the following information:
    ```json
    {
      "username": "<username_from_deployment_credentials_above>",
      "cloudId": "<Cloud_ID_copied_from_deployment_above>"
    }
    ```
  * Create a file named ```private-settings.json``` with the following information:
    ```json
    {
      "password": "<password_from_deployment_credentials_above>"
    }
    ```
## Instructions
  ### Deploy ALL Azure resources and Elastic Agent
  * Login to Azure: ```az login```
  * Run script ```./01deploy_vmss.sh```

  ### Deploy Elastic Agent to already existing VMSS
  * Login to Azure: ```az login```
  * Run script ```./02deploy_elastic_agent.sh -g <azure_resource_group> -v <vmss_cluster_name>```

    