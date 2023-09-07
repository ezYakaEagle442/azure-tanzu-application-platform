# Deploy Tanzu Application Platform to AKS

---
page_type: sample
languages:
- java
products:
- Azure Kubernetes Service
description: "Deploy Tanzu Application Platform to AKS"
urlFragment: "tap"
---


[![Build Status](https://github.com/ezYakaEagle442/azure-tanzu-application-platform/actions/workflows/maven-build.yml/badge.svg)](https://github.com/ezYakaEagle442/azure-tanzu-application-platform/actions/workflows/maven-build.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

[![UI Build Status](https://github.com/ezYakaEagle442/azure-tanzu-application-platform/actions/workflows/maven-build-ui.yml/badge.svg)](https://github.com/ezYakaEagle442/azure-tanzu-application-platform/actions/workflows/maven-build-ui.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

[![Pre-req Deployment status](https://github.com/ezYakaEagle442/azure-tanzu-application-platform/actions/workflows/deploy-iac-pre-req.yml/badge.svg)](https://github.com/ezYakaEagle442/azure-tanzu-application-platform/actions/workflows/deploy-iac-pre-req.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

[![IaC Deployment status](https://github.com/ezYakaEagle442/azure-tanzu-application-platform/actions/workflows/deploy-iac.yml/badge.svg)](https://github.com/ezYakaEagle442/azure-tanzu-application-platform/actions/workflows/deploy-iac.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)


Se also :
- [repo from VMWare](https://github.com/pacphi/gha-workflows-with-gitops-for-tanzu-application-platform/blob/main/docs/AZURE.md)
- [https://tap-gui.demo-aks.spuchol.me](https://tap-gui.demo-aks.spuchol.me)
- [https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap.pdf](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap.pdf)
- [https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap-reference-architecture/GUID-reference-designs-tap-architecture-planning.html](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap-reference-architecture/GUID-reference-designs-tap-architecture-planning.html)

This microservices branch was initially derived from [AngularJS version](https://github.com/spring-petclinic/spring-petclinic-angular1) to demonstrate how to split sample Spring application into [microservices](http://www.martinfowler.com/articles/microservices.html).
To achieve that goal we use IaC with Azure Bicep, MS build of OpenJDK 11, GitHub Actions, Azure AD Workload Identity, Azure Key Vault,  Azure Container Registry, Azure Database for MySQL


See :
- the [AKS Micro-services Reference Architecture](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks-microservices/aks-microservices)
- [https://github.com/Azure-Samples/java-on-azure-examples/tree/main/aks/springboot](https://github.com/Azure-Samples/java-on-azure-examples/tree/main/aks/springboot)

# Pre-req

To get an Azure subscription:
- If you have a Visual studio subscription then you can activate your free credits [here](https://learn.microsoft.com/en-us/azure/devtest/offer/quickstart-individual-credit)  
- If you do not currently have one, you can sign up for a free trial subscription [here](https://azure.com/free)

To install Azure Bicep locally, read [https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)

# CI/CD

## Use GitHub Actions to deploy the Java microservices

About how to build the container image, read :
- [ACR doc](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-java-quickstart) 
- [Optimize docker layers with Spring Boot](https://www.baeldung.com/docker-layers-spring-boot)

Read :
- [https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
- [https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-java-with-maven](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-java-with-maven)
- [Overview of federated identity credentials in Azure Active Directory](https://learn.microsoft.com/en-us/graph/api/resources/federatedidentitycredentials-overview?view=graph-rest-1.0)

You have to specify some [KV secrets](./iac/bicep/modules/kv/kv_sec_key.bicep#L25) that will be then created in the GitHub Action [Azure Infra services deployment workflow](./.github/workflows/deploy-iac-pre-req.yml#L123) :
- SPRING-DATASOURCE-PASSWORD
- SPRING-CLOUD-AZURE-TENANT-ID
- VM-ADMIN-PASSWORD

dash '-' are not supported in GH secrets, so the secrets must be named in GH with underscore '_'.

(ex: the '&' character in the SPRING_DATASOURCE_URL must be escaped with '\&'
jdbc:mysql://petcliaks777.mysql.database.azure.com:3306/petclinic?useSSL=true\&requireSSL=true\&enabledTLSProtocols=TLSv1.2\&verifyServerCertificate=true)

Add the App secrets used by the Spring Config to your GH repo secrets / Actions secrets / Repository secrets / Add :

Secret Name	| Secret Value example
-------------:|:-------:
SPRING_DATASOURCE_PASSWORD | PUT YOUR PASSWORD HERE
SPRING_CLOUD_AZURE_TENANT_ID | PUT YOUR AZURE TENANT ID HERE
VM_ADMIN_PASSWORD | PUT YOUR PASSWORD HERE
TANZU_NET_USER  | PUT YOUR Tanzu Network USER HERE
TANZU_NET_PASSWORD | PUT YOUR Tanzu Network USER PASSWORD HERE
PG_ADM_PWD | PUT YOUR Tanzu Network USER PASSWORD HERE

```bash
LOCATION="westeurope"
RG_KV="rg-kv-tanzu101"
RG_APP="rg-aks-tap-apps"

az group create --name $RG_KV --location $LOCATION
az group create --name $RG_APP --location $LOCATION
```

A Service Principal is required for GitHub Action Runner, read [https://aka.ms/azadsp-cli](https://aka.ms/azadsp-cli)
```bash  
SPN_APP_NAME="gha_aks_tap_run"

# /!\ In CloudShell, the default subscription is not always the one you thought ...
subName="set here the name of your subscription"
subName=$(az account list --query "[?name=='${subName}'].{name:name}" --output tsv)
echo "subscription Name :" $subName

SUBSCRIPTION_ID=$(az account list --query "[?name=='${subName}'].{id:id}" --output tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
```

Add your AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID to your GH repo Settings / Security / Secrets and variables / Actions / Actions secrets / Repository secrets

Read :
- [https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Cwindows#create-a-service-principal-and-add-it-as-a-github-secret)
- [https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Cwindows#use-the-azure-login-action-with-openid-connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Cwindows#use-the-azure-login-action-with-openid-connect)
- [https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp](https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp)

In the GitHub Action Runner, to allow the Service Principal used to access the Key Vault, execute the command below:
```sh

#az ad app create --display-name $SPN_APP_NAME > aad_app.json
# This command will output JSON with an appId that is your client-id. The objectId is APPLICATION-OBJECT-ID and it will be used for creating federated credentials with Graph API calls.

#export APPLICATION_ID=$(cat aad_app.json | jq -r '.appId')
#export APPLICATION_OBJECT_ID=$(cat aad_app.json | jq -r '.id')
#az ad sp create --id $APPLICATION_ID

#export CREDENTIAL_NAME="gha_aks_run"
#export SUBJECT="repo:ezYakaEagle442/azure-tanzu-application-platform:environment:PoC" # "repo:organization/repository:environment:Production"
#export DESCRIPTION="GitHub Action Runner for Petclinic AKS demo"

#az rest --method POST --uri 'https://graph.microsoft.com/beta/applications/$APPLICATION_OBJECT_ID/federatedIdentityCredentials' --body '{"name":"$CREDENTIAL_NAME","issuer":"https://token.actions.githubusercontent.com","subject":"$SUBJECT","description":"$DESCRIPTION","audiences":["api://AzureADTokenExchange"]}'

# SPN_PWD=$(az ad sp create-for-rbac --name $SPN_APP_NAME --skip-assignment --query password --output tsv)
az ad sp create-for-rbac --name $SPN_APP_NAME --skip-assignment --sdk-auth
```

```console
{
  "clientId": "<GUID>",
  "clientSecret": "<GUID>",
  "subscriptionId": "<GUID>",
  "tenantId": "<GUID>",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

Store the above "clientSecret" to SPN_PWD environment variable :
SPN_PWD=XXXXXXXXXXXXXXXXXXXXXXXX

Troubleshoot:
If you hit _["Error: : No subscriptions found for ***."](https://learn.microsoft.com/en-us/answers/questions/738782/no-subscription-found-for-function-during-azure-cl.html)_ , this is related to an IAM privilege in the subscription.

```sh
SPN_APP_ID=$(az ad sp list --all --query "[?appDisplayName=='${SPN_APP_NAME}'].{appId:appId}" --output tsv)
#SPN_APP_ID=$(az ad sp list --show-mine --query "[?appDisplayName=='${SPN_APP_NAME}'].{appId:appId}" --output tsv)
#TENANT_ID=$(az ad sp list --show-mine --query "[?appDisplayName=='${SPN_APP_NAME}'].{t:appOwnerOrganizationId}" --output tsv)
TENANT_ID=$(az ad sp list --all --query "[?appDisplayName=='${SPN_APP_NAME}'].{tenantId:appOwnerOrganizationId}" --output tsv)


# Enterprise Application
az ad app show --id $SPN_APP_ID
az ad app list --show-mine --query "[?displayName=='${SPN_APP_NAME}'].{objectId:id}"

# This is the unique ID of the Service Principal object associated with this application.
# SPN_OBJECT_ID=$(az ad app show --id $SPN_APP_ID --query id -o tsv)
SPN_OBJECT_ID=$(az ad sp list --all --query "[?appDisplayName=='${SPN_APP_NAME}'].{id:id}" --output tsv)

# This is the unique ID of the Service Principal object associated with this application.
az ad sp show --id $SPN_OBJECT_ID

# the assignee is an appId
az role assignment create --assignee $SPN_APP_ID --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_KV} --role contributor
# az role assignment create --assignee $SPN_OBJECT_ID --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_KV} --role contributor

# https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide?tabs=azure-cli#azure-built-in-roles-for-key-vault-data-plane-operations

# "Key Vault Secrets User"
az role assignment create --assignee $SPN_APP_ID --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_KV} --role 4633458b-17de-408a-b874-0445c86b69e6
# az role assignment create --assignee $SPN_OBJECT_ID --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_KV} --role 4633458b-17de-408a-b874-0445c86b69e6

# "Key Vault Secrets Officer"
az role assignment create --assignee $SPN_APP_ID --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_KV} --role b86a8fe4-44ce-4948-aee5-eccb2c155cd7
# az role assignment create --assignee $SPN_OBJECT_ID --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_KV} --role b86a8fe4-44ce-4948-aee5-eccb2c155cd7

# "DNS Zone Contributor"
# https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#dns-zone-contributor
az role assignment create --assignee $SPN_APP_ID --scope /subscriptions/${SUBSCRIPTION_ID} --role befefa01-2a29-4197-83a8-272ff33ce314
#az role assignment create --assignee $SPN_OBJECT_ID --scope /subscriptions/${SUBSCRIPTION_ID} --role befefa01-2a29-4197-83a8-272ff33ce314

# https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#virtual-machine-contributor
# Virtual Machine Contributor has permission 'Microsoft.Network/publicIPAddresses/read'
#az role assignment create --assignee $SPN_APP_ID --scope /subscriptions/${SUBSCRIPTION_ID} --role 9980e02c-c2be-4d73-94e8-173b1dc7cf3c
#az role assignment create --assignee $SPN_OBJECT_ID --scope /subscriptions/${SUBSCRIPTION_ID} --role 9980e02c-c2be-4d73-94e8-173b1dc7cf3c

# Network-contributor: https://learn.microsoft.com/en-us/azure/role-based-access-control/resource-provider-operations#microsoftnetwork
az role assignment create --assignee $SPN_APP_ID --scope /subscriptions/${SUBSCRIPTION_ID} --role 4d97b98b-1d4f-4787-a291-c67834d212e7
#az role assignment create --assignee $SPN_OBJECT_ID --scope /subscriptions/${SUBSCRIPTION_ID} --role 4d97b98b-1d4f-4787-a291-c67834d212e7

# https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal#prerequisites
# /!\ To assign Azure roles, you must have: requires to have Microsoft.Authorization/roleAssignments/write and Microsoft.Authorization/roleAssignments/delete permissions, 
# such as User Access Administrator or Owner.
az role assignment create --assignee $SPN_APP_ID --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_KV} --role Owner
az role assignment create --assignee $SPN_APP_ID --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_APP} --role Owner

#az role assignment create --assignee $SPN_OBJECT_ID --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_KV} --role Owner
#az role assignment create --assignee $SPN_OBJECT_ID --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_APP} --role Owner

```

<span style="color:red">**RBAC Permission model is set on KV, the [pre-req](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide?tabs=azure-cli#prerequisites) requires to have Microsoft.Authorization/roleAssignments/write and Microsoft.Authorization/roleAssignments/delete permissions, such as User Access Administrator or Owner.

[https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal#prerequisites](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal#prerequisites)
To assign Azure roles, you must have: requires to have Microsoft.Authorization/roleAssignments/write and Microsoft.Authorization/roleAssignments/delete permissions, such as User Access Administrator or Owner.
**</span>

<span style="color:red">**"Key Vault Secrets User" [built-in role](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide?tabs=azure-cli#azure-built-in-roles-for-key-vault-data-plane-operations) read secret contents including secret portion of a certificate with private key. Only works for key vaults that use the 'Azure role-based access control' permission model.**
</span>

Read :
- [Use GitHub Actions to connect to Azure documentation](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows).
- [https://github.com/Azure/login#configure-a-service-principal-with-a-secret](https://github.com/Azure/login#configure-a-service-principal-with-a-secret)

Paste in your JSON object for your service principal with the name **AZURE_CREDENTIALS** as secrets to your GH repo Settings / Security / Secrets and variables / Actions / Actions secrets / Repository secrets

You can test your connection with CLI :
```sh
az login --service-principal -u $SPN_APP_ID -p $SPN_PWD --tenant $TENANT_ID
```

Add SUBSCRIPTION_ID, TENANT_ID, SPN_APP_ID and SPN_PWD as secrets to your GH repo Settings / Security / Secrets and variables / Actions / Actions secrets / Repository secrets

Finally Create a GH [PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) "GH_PAT" that can be use to , [publish packages](./.github/workflows/maven-build.yml#L176) and [delete packages](./.github/workflows/delete-all-artifacts.yml)

<span style="color:red">**Your GitHub [personal access token](https://github.com/settings/tokens?type=beta) needs to have the workflow scope selected. You need at least delete:packages and read:packages scopes to delete a package. You need contents: read and packages: write permissions to publish and download artifacts**</span>

Create SSH Keys, WITHOUT any passphrase (type enter if prompt)

```sh
# https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.resources/deployment-script-ssh-key-gen/new-key.sh
export ssh_key=aksadm
echo -e 'y' | ssh-keygen -t rsa -b 4096 -f ~/.ssh/$ssh_key -C "youremail@groland.grd" # -N $ssh_passphrase
# test
# ssh -i ~/.ssh/$ssh_key $admin_username@$network_interface_pub_ip
```

Add $ssh_key & $ssh_key.pub as secrets SSH_PRV_KEY & SSH_PUB_KEY to your GH repo Settings / Security / Secrets and variables / Actions / Actions secrets / Repository secrets

To avoid to hit the error below : 
```console
"The subscription is not registered to use namespace 'Microsoft.KeyVault'. See https://aka.ms/rps-not-found for how to register subscriptions.\",\r\n    \"details\": [\r\n      ***\r\n        \"code\": \"MissingSubscriptionRegistration\"
```

Read the [docs](https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider?tabs=azure-cli)
Just run :
```sh
az feature list --output table --namespace Microsoft.ContainerService
az feature register --namespace "Microsoft.ContainerService" --name "AKS-GitOps"
az feature register --namespace "Microsoft.ContainerService" --name "EnableWorkloadIdentityPreview"
az feature register --namespace "Microsoft.ContainerService" --name "AKS-Dapr"
az feature register --namespace "Microsoft.ContainerService" --name "EnableAzureKeyvaultSecretsProvider"
az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzureDefender"
az feature register --namespace "Microsoft.ContainerService" --name "AKS-PrometheusAddonPreview" 
az feature register --namespace "Microsoft.ContainerService" --name "AutoUpgradePreview"
az feature register --namespace "Microsoft.ContainerService" --name "AKS-OMSAppMonitoring"
az feature register --namespace "Microsoft.ContainerService" --name "ManagedCluster"
az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzurePolicyAutoApprove"
az feature register --namespace "Microsoft.ContainerService" --name "FleetResourcePreview"

az provider list --output table
az provider list --query "[?registrationState=='Registered']" --output table
az provider list --query "[?namespace=='Microsoft.KeyVault']" --output table
az provider list --query "[?namespace=='Microsoft.OperationsManagement']" --output table

az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.OperationalInsights 
az provider register --namespace Microsoft.DBforMySQL
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.Compute 
az provider register --namespace Microsoft.AppConfiguration       
az provider register --namespace Microsoft.AppPlatform
az provider register --namespace Microsoft.EventHub  
az provider register --namespace Microsoft.Kubernetes 
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.Kusto  
az provider register --namespace Microsoft.ManagedIdentity
az provider register --namespace Microsoft.Monitor
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.Network  

az provider register --namespace Microsoft.ServiceBus
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Subscription

# https://learn.microsoft.com/en-us/azure/aks/cluster-extensions
az extension add --name k8s-extension
az extension update --name k8s-extension

# https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-flux2?
az extension add -n k8s-configuration

```

## K8S Tips


```sh
  source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
  echo "source <(kubectl completion bash)" >> ~/.bashrc 
  alias k=kubectl
  complete -F __start_kubectl k

  alias kn='kubectl config set-context --current --namespace '

  export gen="--dry-run=client -o yaml"

  alias kp="kubectl get pods -o wide"
  alias kd="kubectl get deployment -o wide"
  alias ks="kubectl get svc -o wide"
  alias kno="kubectl get nodes -o wide"

  alias kdp="kubectl describe pod"
  alias kdd="kubectl describe deployment"
  alias kds="kubectl describe service"

  vi ~/.vimrc
  set ts=2 sw=2
  . ~/.vimrc
```

## AKS integration with AAD pre-req

[https://learn.microsoft.com/en-us/azure/aks/managed-aad](https://learn.microsoft.com/en-us/azure/aks/managed-aad)

```sh

# List existing groups in the directory
#az ad group list --filter "displayname eq '<group-name>'" -o table
az ad group list -o table

# Create an Azure AD group
AAD_ADM_GRP="AKS TAP Admin Group"
az ad group create --display-name "$AAD_ADM_GRP" --mail-nickname akstapadmingroup
aad_admin_group_object_id=$(az ad group show -g "$AAD_ADM_GRP" --query id -o tsv)
echo "aad_admin_group_object_id" : $aad_admin_group_object_id

# Add Users to the above Azure AD Admin Group

# The object ID of the User, or service principal.
USR_ID=$(az account show --query user.name -o tsv)
USR_SPN_ID=$(az ad user show --id ${USR_ID} --query id -o tsv)
az ad group member add --member-id $USR_SPN_ID -g $aad_admin_group_object_id

SPN_APP_NAME="gha_aks_tap_run"
SPN_OBJECT_ID=$(az ad sp list --all --query "[?appDisplayName=='${SPN_APP_NAME}'].{id:id}" --output tsv)
az ad group member add --member-id $SPN_OBJECT_ID -g $aad_admin_group_object_id


TAP_GUI_BACKSTAGE_APP_NAME=tap_gui_backstage
az ad app create --display-name $TAP_GUI_BACKSTAGE_APP_NAME > aad_app_tap_gui_backstage.json
# This command will output JSON with an appId that is your client-id. The objectId is APPLICATION-OBJECT-ID 

export TAP_BACKSTAGE_AUTH_MICROSOFT_CLIENT_ID=$(cat aad_app_tap_gui_backstage.json | jq -r '.appId')
export TAP_BACKSTAGE_AUTH_MICROSOFT_TENANT_ID=$(az account show --query tenantId -o tsv)
export TAP_BACKSTAGE_AUTH_MICROSOFT_OBJECT_ID=$(cat aad_app_tap_gui_backstage.json | jq -r '.id')

az ad sp create --id $TAP_BACKSTAGE_AUTH_MICROSOFT_CLIENT_ID > aad_sp_tap_gui_backstage.json

az ad app credential reset --id $TAP_BACKSTAGE_AUTH_MICROSOFT_CLIENT_ID >  aad_app_secret_tap_gui_backstage.json
export TAP_BACKSTAGE_AUTH_MICROSOFT_CLIENT_SECRET=$(cat aad_app_secret_tap_gui_backstage.json | jq -r '.password')


TAP_GUI_BACKSTAGE_APP_ID=$(az ad sp list --all --query "[?appDisplayName=='${TAP_GUI_BACKSTAGE_APP_NAME}'].{appId:appId}" --output tsv)
TAP_GUI_BACKSTAGE_OBJECT_ID=$(az ad sp list --all --query "[?appDisplayName=='${TAP_GUI_BACKSTAGE_APP_NAME}'].{id:id}" --output tsv)

TAP_GUI_BACKSTAGE_APP_OBJECT_ID=$(az ad app list --filter "displayName eq '$TAP_GUI_BACKSTAGE_APP_NAME'" --query "[?displayName=='$TAP_GUI_BACKSTAGE_APP_NAME'].{id:id}" -o tsv | tr -d '\r')

az ad app show --id $TAP_GUI_BACKSTAGE_APP_OBJECT_ID

```

Add AAD_ADM_GRP as secrets AAD_ADM_GRP to your GH repo Settings / Security / Secrets and variables / Actions / Actions secrets / Repository secrets


Add TAP_BACKSTAGE_AUTH_MICROSOFT_CLIENT_ID, TAP_BACKSTAGE_AUTH_MICROSOFT_CLIENT_SECRET & TAP_BACKSTAGE_AUTH_MICROSOFT_TENANT_ID as secrets to your GH repo Settings / Security / Secrets and variables / Actions / Actions secrets / Repository secrets

# CI/CD Post-Install

Once the IaC deployment workflow is sucessfully completed follow those nex tsteps to continue TAP Installation.

Read [https://azure.github.io/azure-workload-identity/docs/installation/azwi.html](https://azure.github.io/azure-workload-identity/docs/installation/azwi.html)

Install Azure AD Workload Identity CLI
```sh
AAD_WI_CLI_VERSION=1.0.0-beta.0 # 0.15.0
wget https://github.com/Azure/azure-workload-identity/releases/download/v$AAD_WI_CLI_VERSION/azwi-v$AAD_WI_CLI_VERSION-linux-amd64.tar.gz
gunzip azwi-v$AAD_WI_CLI_VERSION-linux-amd64.tar.gz
tar -xvf azwi-v$AAD_WI_CLI_VERSION-linux-amd64.tar
./azwi version

```

Once the AKS cluster is created, creates Dev & Ops Groups :

```sh
LOCATION="westeurope"
AKS_CLUSTER_NAME="aks-tap42"
RG_APP="rg-aks-tap-apps"
TANZU_INSTALL_DIR=tanzu
APP_NAME=tap42

aks_cluster_id=$(az aks show -n $AKS_CLUSTER_NAME -g $RG_APP --query id -o tsv)
echo "AKS cluster ID : " $aks_cluster_id

# Create the first example group in Azure AD for the application developers
APPDEV_ID=$(az ad group create --display-name appdev-${APP_NAME} --mail-nickname appdev-${APP_NAME} --query id -o tsv)
echo "APPDEV GROUP ID: " $APPDEV_ID
az role assignment create --assignee $APPDEV_ID --role "Azure Kubernetes Service Cluster User Role" --scope $aks_cluster_id

# Create a second example group, this one for SREs named opssre
OPSSRE_ID=$(az ad group create --display-name opssre-${APP_NAME} --mail-nickname opssre-${APP_NAME} --query id -o tsv)
echo "OPSSRE GROUP ID: " $OPSSRE_ID
az role assignment create --assignee $OPSSRE_ID --role "Azure Kubernetes Service Cluster User Role" --scope $aks_cluster_id

password=P@ssw0rd1 # Change it !!!
# You must use one of the verified domain names in your organization ex: foo@xxxEnvMCAP123456.onmicrosoft.com
VERIFIED_DOMAIN=xxxEnvMCAP123456.onmicrosoft.com

# Create a user for the Dev role
AKSDEV_ID=$(az ad user create --display-name "AKS Dev ${APP_NAME}" --user-principal-name "aksdev@$VERIFIED_DOMAIN" --password $password --query id -o tsv)
echo "AKS DEV USER ID: " $AKSDEV_ID

# Add the user to the appdev Azure AD group
az ad group member add --member-id $AKSDEV_ID --group appdev-${APP_NAME} 

# Create a user for the SRE role
AKSSRE_ID=$(az ad user create --display-name "AKS SRE ${APP_NAME}" --user-principal-name "akssre@$VERIFIED_DOMAIN" --password  $password --query id -o tsv)
echo "AKS SRE USER ID: " $AKSSRE_ID

# Add the user to the opssre Azure AD group
az ad group member add --member-id $AKSSRE_ID --group opssre-${APP_NAME}


# https://learn.microsoft.com/en-us/azure/aks/managed-aad#prerequisites
helm version

KUBELOGIN_VERSION=0.0.27
wget https://github.com/Azure/kubelogin/releases/download/v$KUBELOGIN_VERSION/kubelogin-linux-amd64.zip # -O kubelogin
sudo apt install unzip
unzip kubelogin-linux-amd64.zip
ls -al bin/linux_amd64/kubelogin
sudo mv bin/linux_amd64/kubelogin /usr/local/bin
ls -al /usr/local/bin/kubelogin

# Copy the latest Releases to shell's search path.
#vim ~/.profile
#. .profile
#vim ~/.bashrc

az aks get-credentials --name $AKS_CLUSTER_NAME -g $RG_APP

export KUBECONFIG=~/.kube/config
which kubelogin 
kubelogin --version
kubelogin convert-kubeconfig -l azurecli

kubectl get no

kubectl apply -f $TANZU_INSTALL_DIR/k8s/role-dev-namespace.yaml
kubectl apply -f $TANZU_INSTALL_DIR/k8s/role-sre-namespace.yaml

export DEV_GROUP_OBECT_ID=$APPDEV_ID
envsubst < $TANZU_INSTALL_DIR/k8s/rolebinding-dev-namespace.yaml > $TANZU_INSTALL_DIR/k8s/deploy/rolebinding-dev-namespace.yaml
cat $TANZU_INSTALL_DIR/k8s/deploy/rolebinding-dev-namespace.yaml
kubectl apply -f ./$TANZU_INSTALL_DIR/k8s/deploy/rolebinding-dev-namespace.yaml
kubectl describe role dev-user-full-access -n development
kubectl describe rolebindings dev-user-access -n development

export SRE_GROUP_OBECT_ID=$OPSSRE_ID
envsubst < ./$TANZU_INSTALL_DIR/k8s/rolebinding-sre-namespace.yaml > ./$TANZU_INSTALL_DIR/k8s/deploy/rolebinding-sre-namespace.yaml
kubectl apply -f ./$TANZU_INSTALL_DIR/k8s/deploy/rolebinding-sre-namespace.yaml

export AKS_ADM_GROUP_OBECT_ID=$aad_admin_group_object_id
envsubst < ./$TANZU_INSTALL_DIR/k8s/aad-cluster-admin-binding.yaml > ./$TANZU_INSTALL_DIR/k8s/deploy/aad-cluster-admin-binding.yaml
cat ./$TANZU_INSTALL_DIR/k8s/deploy/aad-cluster-admin-binding.yaml
kubectl apply -f $TANZU_INSTALL_DIR/k8s/deploy/aad-cluster-admin-binding.yaml

kubectl apply -f $TANZU_INSTALL_DIR/k8s/aad-kapp-controller-binding.yaml
kubectl apply -f $TANZU_INSTALL_DIR/k8s/aad-metadata-store-binding.yaml
kubectl apply -f $TANZU_INSTALL_DIR/k8s/aad-tanzu-ingress-binding.yaml
kubectl apply -f $TANZU_INSTALL_DIR/k8s/aad-tap-install-binding.yaml

kubectl get clusterrolebindings -A
kubectl describe clusterrolebindings owner-cluster-admin
kubectl describe clusterrolebindings aks-cluster-admin-binding
kubectl describe clusterrolebindings aks-cluster-admin-binding-aad
kubectl get clusterroles -A
kubectl describe clusterrole admin
kubectl describe clusterrole cluster-admin

```



## Tanzu pre-req


Create a folder named "tanzu" on your workstattion / local git grepo.
The here under folders are already excluded in the .gitignore :
- tanzu/cli/*
- tanzu/tanzu-framework-linux-amd64-v0.25.4.tar
- tanzu/tanzu-cluster-essentials-linux-amd64-1.4.0.tgz

Read [Tanzu docs](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/prerequisites.html) to get the pre-req.
You will get 3 files, and save them to the tanzu folder : 
- tanzu/tanzu-framework-linux-amd64-v0.25.4.tar (the version name must match M.n.p like v0.25.4 NOT v0.25.4.1)
- tanzu/tanzu-cluster-essentials-linux-amd64-1.4.0.tgz
- tap-gui-blank-catalog.tgz

Those files are too big to get pushed using git CLI, instead you will upload them during the IaC deployment as soon as the Storage account is created.
Once the Storage account is created, run this CLI snippet from your workstation : 


```sh
# "/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
# your subscription must have Role "Storage Blob Data Contributor" 
USR_ID=$(az account show --query user.name -o tsv | tr -d '\r')
USR_SPN_ID=$(az ad user show --id ${USR_ID} --query id -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv  | tr -d '\r')

AZ_STORAGE_NAME=statapXXX
az role assignment create --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_APP}" --role "Storage Blob Data Contributor" --assignee-principal-type "User" --assignee-object-id "$USR_SPN_ID"

# ==== Tanzu Tools ====

TANZU_INSTALL_DIR=./tanzu
TANZU_CLI=tanzu-framework-linux-amd64-v0.25.4.tar # /!\ the version name must match M.n.p like v0.25.4 NOT v0.25.4.1
TANZU_ESSENTIALS=tanzu-cluster-essentials-linux-amd64-1.4.0.tgz
TANZU_GUI_CAT=tap-gui-blank-catalog.tgz

TANZU_BLOB_CLI=tanzu-cli
TANZU_BLOB_ESSENTIALS=tanzu-essentials
TANZU_BLOB_GUI_CAT=tanzu-catalog

RG_APP=rg-aks-tap-apps # RG where to deploy the other Azure services: AKS, TAP, ACR, MySQL, etc.

# ==== Azure storage , values must be consistent with the ones in iac/bicep/modules/aks/storage.bicep ====

AZ_STORAGE_NAME=statapaks # customize this
AZ_BLOB_CONTAINER_NAME=statapaks-blob # customize this
# AZ_BLOB_SVC_NAME: default # MUST NOT BE MODIFIED

# https://learn.microsoft.com/en-us/rest/api/storageservices/setting-timeouts-for-blob-service-operations
AZ_BLOB_MAX_CONNECTIONS=10
AZ_BLOB_MAXSIZE_CONDITION=440401920 # 420 Mb
AZ_BLOB_TIMEOUT=600

LOCAL_IP=$(curl whatismyip.akamai.com)
echo "LOCAL_IP="$LOCAL_IP

az config set extension.use_dynamic_install=yes_without_prompt
echo "About to upload tools to Azure BLOB Storage. /!\ --overwrite' is in preview and under development"
echo "AZ_BLOB_MAX_CONNECTIONS=$AZ_BLOB_MAX_CONNECTIONS"
echo "AZ_BLOB_TIMEOUT=$AZ_BLOB_TIMEOUT "
echo "AZ_BLOB_MAX_CONNECTIONS=$AZ_BLOB_MAX_CONNECTIONS"

echo "About to ADD network-rule to ALLOW $LOCAL_IP to Azure BLOB Storage AZ_STORAGE_NAME"
az storage account network-rule add --ip-address $LOCAL_IP --account-name  $AZ_STORAGE_NAME  --action "Allow" -g $RG_APP  --only-show-errors

# https://learn.microsoft.com/en-us/rest/api/storageservices/setting-timeouts-for-blob-service-operations
az storage blob upload --name $TANZU_GUI_CAT --file $TANZU_INSTALL_DIR/$TANZU_GUI_CAT --container-name $AZ_BLOB_CONTAINER_NAME --account-name $AZ_STORAGE_NAME --auth-mode login --overwrite --max-connections $AZ_BLOB_MAX_CONNECTIONS --timeout $AZ_BLOB_TIMEOUT

az storage blob upload --name  $TANZU_BLOB_CLI --file $TANZU_INSTALL_DIR/$TANZU_CLI --container-name $AZ_BLOB_CONTAINER_NAME --account-name $AZ_STORAGE_NAME --auth-mode login --overwrite --max-connections $AZ_BLOB_MAX_CONNECTIONS --timeout $AZ_BLOB_TIMEOUT

az storage blob upload --name  $TANZU_BLOB_ESSENTIALS --file $TANZU_INSTALL_DIR/$TANZU_ESSENTIALS --container-name $AZ_BLOB_CONTAINER_NAME --account-name $AZ_STORAGE_NAME --auth-mode login --overwrite --max-connections $AZ_BLOB_MAX_CONNECTIONS --timeout $AZ_BLOB_TIMEOUT

echo "About to REMOVE network-rule ALLOWING $LOCAL_IP to Azure BLOB Storage $AZ_STORAGE_NAME"
az storage account network-rule remove --ip-address $LOCAL_IP --account-name  $AZ_STORAGE_NAME -g $RG_APP --only-show-errors

```


Install TAP CLI on your workstation/WSL
```sh
TANZU_INSTALL_DIR=tanzu
TANZU_CLI_VERSION=v0.25.4 # file name must have version with v0.25.4 NOT v0.25.4.1

tar -xvf $TANZU_INSTALL_DIR/tanzu-framework-linux-amd64-$TANZU_CLI_VERSION.tar -C $TANZU_INSTALL_DIR
export TANZU_CLI_NO_INIT=true

TANZU_ESSENTIALS=tanzu-cluster-essentials-linux-amd64-1.4.0.tgz
tar -xvf $TANZU_INSTALL_DIR/$TANZU_ESSENTIALS -C $TANZU_INSTALL_DIR

cd $TANZU_INSTALL_DIR
export VERSION=$TANZU_CLI_VERSION
sudo install cli/core/$VERSION/tanzu-core-linux_amd64 /usr/local/bin/tanzu

tanzu version
tanzu plugin install --local cli all
tanzu plugin list

sudo cp kapp /usr/local/bin/kapp
sudo cp imgpkg /usr/local/bin/imgpkg

kapp --help
imgpkg copy --help

cd ..
```

### Prepare Tanzu Template file

Check & modify the file .env or setenv.bat :
```sh
export $(cat .env | xargs)

pwd
mkdir ./$TANZU_INSTALL_DIR/deploy
envsubst < ./$TANZU_INSTALL_DIR/tap-values.yml > ./$TANZU_INSTALL_DIR/deploy/tap-values.yml
echo "Cheking folder " ./$TANZU_INSTALL_DIR/deploy
ls -al ./$TANZU_INSTALL_DIR/deploy
cat ./$TANZU_INSTALL_DIR/deploy/tap-values.yml

```
### Replace URL in your own repos

Fork those repos : 
- [https://github.com/ezYakaEagle442/tanzu-simple](https://github.com/ezYakaEagle442/tanzu-simple)
- [https://github.com/ezYakaEagle442/tap-catalog](https://github.com/ezYakaEagle442/tap-catalog)
- [https://github.com/ezYakaEagle442/tanzu-tools](https://github.com/ezYakaEagle442/tanzu-tools)
- [https://github.com/ezYakaEagle442/tanzu-app-deploy](https://github.com/ezYakaEagle442/tanzu-app-deploy)

https://github.com/ezYakaEagle442/tanzu-simple/blob/main/k8s/02-deployment.yml#L18 ==> image d'ACR a remplacer
https://github.com/ezYakaEagle442/tanzu-simple/blob/main/config/workload.yaml#L15
https://github.com/ezYakaEagle442/tanzu-simple/blob/main/config/deliverable.yaml#L19

https://github.com/ezYakaEagle442/tap-catalog/blob/main/api/petstore.yaml#L17
https://github.com/ezYakaEagle442/tap-catalog/blob/main/api/tanzu-app.yaml#L17
https://github.com/ezYakaEagle442/tap-catalog/blob/main/api/openapi/openapi-tanzu-app.yaml#L7 ==> URL mut be updated

https://github.com/ezYakaEagle442/tanzu-tools/blob/main/tap/data/workload.yaml#L14 ==> URL mut be updated



### Troubleshoot

troubleshoot namespace stuck in terminating-state read [this](https://www.ibm.com/docs/en/cloud-private/3.2.0?topic=console-namespace-is-stuck-in-terminating-state).
```sh
# 
kubectl get namespaces

i=0
for ns in $(kubectl get ns -o=custom-columns=:.metadata.name)
do
  for status in $(kubectl get ns $ns -o=custom-columns=:status.phase)
  do     
    if [[ "$status" == "Terminating" ]]
      then
        echo "Verifying Namespace $ns with status $status"
        kubectl get namespace $ns -o json > tmp-$i.json
        i=$((i+1))
        echo "i="$i
    fi    
  done
done


# Edit your tmp.json file. Remove the kubernetes value from the finalizers field and save the file. It should look like :
#    "spec": {
#    },

i=0
for ns in $(kubectl get ns -o=custom-columns=:.metadata.name)
do
  for status in $(kubectl get ns $ns -o=custom-columns=:status.phase)
  do     
    if [[ "$status" == "Terminating" ]]
      then
        echo "Verifying Namespace $ns with status $status"
        curl -k -H "Content-Type: application/json" -X PUT --data-binary @tmp-$i.json http://127.0.0.1:8001/api/v1/namespaces/$ns/finalize
        i=$((i+1))
        echo "i="$i
    fi    
  done
done

# cat bad.json | jq '. | setpath(["metadata","finalizers"]; [])' | curl -kD- -H "Content-Type: application/json" -X PUT --#data-binary @- "127.0.0.1:8001$(cat bad.json | jq -r '.metadata.selfLink')"

# To set a temporary proxy IP and port, run the following command. Be sure to keep your terminal window open until you delete the stuck namespace
kubectl proxy

kubectl get namespaces


# To add a dummy Pod to connect to it : 
kubectl run dummy --image=nginx --restart=Never --port=80 -n tap-gui

kubectl exec -it dummy -n tap-gui -- bash
  curl http://server:7000

# https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/tap-gui-install-tap-gui.html
export ING_HOST=tap.appinno.com #tap.westeurope.cloudapp.azure.com
echo "INGRESS HOST " $ING_HOST
mkdir $TANZU_INSTALL_DIR/k8s/deploy
envsubst < $TANZU_INSTALL_DIR/k8s/contour-ingress.yaml > $TANZU_INSTALL_DIR/k8s/deploy/contour-ingress.yaml
cat $TANZU_INSTALL_DIR/k8s/deploy/contour-ingress.yaml
kubectl apply -f $TANZU_INSTALL_DIR/k8s/deploy/contour-ingress.yaml -n tap-gui

kubectl get ing -n tap-gui
kubectl get httpproxy -n tap-gui

# https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/tap-gui-tls-cert-mngr-ext-clusterissuer.html
envsubst < $TANZU_INSTALL_DIR/k8s/letsencrypt-prod-cluster-issuer.yaml > $TANZU_INSTALL_DIR/k8s/deploy/letsencrypt-prod-cluster-issuer.yaml
cat $TANZU_INSTALL_DIR/k8s/deploy/letsencrypt-prod-cluster-issuer.yaml
kubectl apply -f $TANZU_INSTALL_DIR/k8s/deploy/letsencrypt-prod-cluster-issuer.yaml -n cert-manager
kubectl get clusterissuer -A -o wide
kubectl describe clusterissuer letsencrypt-production
kubectl get certs -n cert-manager

tanzu package installed update tap -p tap.tanzu.vmware.com -v 1.4.0  --values-file tap-values.yaml -n tap-install

```


troubleshoot Git error :
[https://docs.github.com/en/repositories/working-with-files/managing-large-files/removing-files-from-git-large-file-storage](https://docs.github.com/en/repositories/working-with-files/managing-large-files/removing-files-from-git-large-file-storage)
```console
remote: error: File tanzu/tanzu-framework-linux-amd64-v0.25.4.1.tar is 234.56 MB; this exceeds GitHub's file size limit of 100.00 MB
remote: error: GH001: Large files detected. You may want to try Git Large File Storage - https://git-lfs.github.com.
To github.com:ezYakaEagle442/azure-tanzu-application-platform
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to 'git@github.com:ezYakaEagle442/azure-tanzu-application-platform'
```

```sh
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch tanzu/tanzu-framework-linux-amd64-v0.25.4.1.tar' \
  --prune-empty --tag-name-filter cat -- --all

git commit --amend -CHEAD

git push
```

## Workflows

See GitHub Actions :
- [Deploy the Azure Infra services workflow](./.github/workflows/deploy-iac.yml)
- [Maven Backends Build workflow](./.github/workflows/maven-build.yml)
- [Maven UI Build workflow](./.github/workflows/maven-build-ui.yml)
- [Java Apps Backends Deploy workflow](./.github/workflows/deploy-app-svc.yml)
- [Java Apps UI Deploy workflow](./.github/workflows/deploy-app-ui.yml)
- [Delete ALL the Azure Infra services workflow, except KeyVault](./.github/workflows/delete-rg.yml)


<span style="color:red">****</span>

Workflow Design

The Workflow run the steps in this in this order :

```
├── Deploy the Azure Infra services workflow ./.github/workflows/deploy-iac.yml
│   ├── Trigger the pre-req ./.github/workflows/deploy-iac.yml#L75
│       ├── Create Azure Key Vault ./.github/workflows/deploy-iac-pre-req.yml#L108
│       ├── Authorize local IP to access the Azure Key Vault ./.github/workflows/deploy-iac-pre-req.yml#L115
│       ├── Create the secrets ./.github/workflows/deploy-iac-pre-req.yml#L121
│       ├── Disable local IP access to the Key Vault ./.github/workflows/deploy-iac-pre-req.yml#L152
│       ├── Deploy the pre-req ./.github/workflows/deploy-iac-pre-req.yml#L180
│           ├── Create Log Analytics Workspace ./iac/bicep/pre-req.bicep#L68
│           ├── Create appInsights  ./iac/bicep/pre-req.bicep#L68
│           ├── Create ACR ./iac/bicep/pre-req.bicep#L104
│           ├── Create Identities ./iac/bicep/pre-req.bicep#L124
│           ├── Create VNet ./iac/bicep/pre-req.bicep#L135
│           ├── Create roleAssignments ./iac/bicep/pre-req.bicep#L155
│           ├── Create MySQL ./iac/bicep/pre-req.bicep#L174
│   ├── Deploy AKS ./iac/bicep/main.bicep
│       ├── Call AKS module ./iac/bicep/main.bicep#L95
│       ├── Whitelist AKS Env. OutboundIP to KV and MySQL ./.github/workflows/deploy-iac.yml#L119
│       ├── Call DB data loading Init ./.github/workflows/deploy-iac.yml#L154
│       ├── Call Maven Build ./.github/workflows/deploy-iac.yml#L159
│       ├── Maven Build ./.github/workflows/maven-build.yml#L128
│           ├── Publish the Maven package ./.github/workflows/maven-build.yml#L176
│           ├── Build image and push it to ACR ./.github/workflows/maven-build.yml#L241
│       ├── Call Maven Build-UI ./.github/workflows/deploy-iac.yml#L166
│           ├── Build image and push it to ACR ./.github/workflows/maven-build-ui.yml#L191
│       ├── Deploy Backend Services ./.github/workflows/deploy-iac.yml#L185
│           ├── Deploy Backend services calling ./.github/workflows/deploy-app-svc.yml
│           ├── Deploy the UI calling ./.github/workflows/deploy-app-ui.yml
```


You need to set your own param values in :


- [Azure Infra services deployment workflow](./.github/workflows/deploy-iac.yml#L10)

```sh
env:
  # ==== Versions ====

  DEPLOYMENT_VERSION: 2.6.13
  AZ_CLI_VERSION: 2.45.0
  JAVA_VERSION: 11

  # ==== General settings  ====

  APP_NAME: tap42
  LOCATION: westeurope # francecentral
  RG_KV: rg-kv-tanzu101 # RG where to deploy KV
  RG_APP: rg-aks-tap-apps # RG where to deploy the other Azure services: AKS, TAP, ACR, MySQL, etc.

  # DNS  
  DNS_ZONE: cloudapp.azure.com
  APP_DNS_ZONE: tap.westeurope.cloudapp.azure.com
  CUSTOM_DNS: appinnohandsonlab.com # set here your own domain name
  AZURE_DNS_LABEL_NAME: petclinic

  TAP_NAMESPACE: tanzu
  PETCLINIC_NAMESPACE: petclinic
  AKS_CLUSTER_NAME: aks-tap42
  VNET_NAME: vnet-aks

  DNS_PREFIX: tanzu-tap42 # customize this param
  ING_NS: ingress # Namespace to use for the Ingress Controller
  AKS_IDENTITY_NAME: id-aks-tap42-cluster-dev-westeurope-101 # customize this , MUST BE 'id-aks-${appName}-cluster-dev-${location}-101'

  # ==== Identities ====:
  CUSTOMERS_SVC_APP_ID_NAME: id-aks-tap42-petclinic-customers-service-dev-westeurope-101 # customize this, MUST BE 'id-aks-${appName}-petclinic-customers-service-dev-${location}-101'
  VETS_SVC_APP_ID_NAME: id-aks-tap42-petclinic-vets-service-dev-westeurope-101 # customize this, MUST BE 'id-aks-${appName}-petclinic-vets-service-dev-${location}-101'
  VISITS_SVC_APP_ID_NAME: id-aks-tap42-petclinic-visits-service-dev-westeurope-101 # customize this, MUST BE 'id-aks-${appName}-petclinic-visits-service-dev-${location}-101'
  CONFIG_SERVER_APP_ID_NAME: id-aks-tap42-petclinic-config-server-dev-westeurope-101 # customize this, MUST BE  'id-aks-${appName}-petclinic-config-server-dev-${location}-101'
 
   # MySQL
  MYSQL_SERVER_NAME: tap42
  MYSQL_DB_NAME: petclinic
  MYSQL_ADM_USR: mys_adm
  MYSQL_TIME_ZONE: Europe/Paris
  MYSQL_CHARACTER_SET: utf8
  MYSQL_COLLATION: utf8_general_ci 
  MYSQL_PORT: 3306
  MYSQL_VERSION: "5.7" # "8.0.21"

   # SKU common for MySQL & PG
  DB_SKU_NAME: Standard_B1ms
  DB_SKU_TIER : Burstable

  # PG
  PG_SERVER_NAME: tap42
  PG_DB_NAME: tap
  PG_ADM_USR: pgs_adm
  PG_TIME_ZONE: Europe/Paris
  PG_CHARACTER_SET: utf8
  PG_COLLATION: fr_FR.utf8 # select * from pg_collation ;
  PG_PORT: 5432
  PG_VERSION: "13"
```

- [Maven Build workflow](./.github/workflows/maven-build.yml)
```sh

  # ==== Versions ====

  DEPLOYMENT_VERSION: 2.6.13
  AZ_CLI_VERSION: 2.45.0
  JAVA_VERSION: 11

  # ==== General settings  ====

  RG_KV: rg-kv-tanzu101 # RG where to deploy KV
  RG_APP: rg-aks-tap-apps # RG where to deploy the other Azure services: AKS, TAP, ACR, MySQL, etc.

  REPOSITORY: tap                  # set this to your ACR repository
  PROJECT_NAME: petclinic                # set this to your project's name

```


- [Maven Build workflow for the UI](./.github/workflows/maven-build-ui.yml)

```sh
env:

  # ==== Versions ====
  
  DEPLOYMENT_VERSION: 2.6.13
  AZ_CLI_VERSION: 2.45.0
  JAVA_VERSION: 11

  # ==== General settings  ====

  RG_APP: rg-aks-tap-apps # RG where to deploy the other Azure services: AKS, TAP, ACR, MySQL, etc.
  REPOSITORY: tap                  # set this to your ACR repository

```

Once you commit, then push your code update to your repo, it will trigger a Maven build which you need to can CANCELL from https://github.com/USERNAME/azure-tanzu-application-platform/actions/workflows/maven-build.yml the first time you trigger the workflow, anyway it will fail because the ACR does not exist yet and the docker build will fail to push the Images.

Note: the GH Hosted Runner / [Ubuntu latest image has already Azure CLI installed](https://github.com/actions/runner-images/blob/main/images/linux/Ubuntu2204-Readme.md#cli-tools)


- [Tanzu Setup](./.github/workflows/tap-setup.yml)

```sh
env:

  # ==== Versions ====
  
  TANZU_CLI_VERSION: v0.25.4
  TAP_VERSION_NUMBER: 1.4.0
  CERT_MANAGER_VERSION: v1.11.0
  AZ_CLI_VERSION: 2.45.0

  # ==== General settings  ====

  APP_NAME: tap42
  LOCATION: westeurope # francecentral
  RG_KV: rg-kv-tanzu101 # RG where to deploy KV
  RG_APP: rg-aks-tap-apps # RG where to deploy the other Azure services: AKS, TAP, ACR, MySQL, etc.
  
  #DNS_ZONE: cloudapp.azure.com
  #APP_DNS_ZONE: westeurope.cloudapp.azure.com
  CUSTOM_DNS: appinnohandsonlab.com
  AZURE_DNS_LABEL_NAME: tap-gui
  TANZU_DNS_CHILD_ZONE: tap.appinnohandsonlab.com

  CATALOG_URL: https://github.com/ezYakaEagle442/tap-catalog

```



# DNS Management

cloudapp.azure.com DNZ zone can not be used because child zone *.tap.<DOMAIN-NAME> is required, ex: tap-gui.tap.mydomain.com.
You must therefote use your own custom domain, once the IaC workflows has sucessfully deployed AKS and the Azure DNS zone,  

[https://docs.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns#delegate-the-domain](https://docs.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns#delegate-the-domain)

```sh
LOCATION="westeurope"
RG_APP="rg-aks-tap-apps"
DNS_ZONE="appinno.com" # set here your own domain name

ns_server=$(az network dns record-set ns show --zone-name $DNS_ZONE --name @ -g $RG_APP --query nsRecords[0] --output tsv)
ns_server_length=$(echo -n $ns_server | wc -c)
ns_server="${ns_server:0:$ns_server_length-1}"
echo "Name Server 1" $ns_server

ns_server=$(az network dns record-set ns show --zone-name $DNS_ZONE --name @ -g $RG_APP --query nsRecords[1] --output tsv)
ns_server_length=$(echo -n $ns_server | wc -c)
ns_server="${ns_server:0:$ns_server_length-1}"
echo "Name Server 2" $ns_server

```
In the registrar's DNS management page, edit the NS records and replace the NS records with the Azure DNS name servers.

```sh
nslookup $DNS_ZONE $ns_server
```

# Integrate TAP with AAD

Read [https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/authn-authz-azure-ad.html](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.4/tap/authn-authz-azure-ad.html)

Identify or create a list of groups in the Azure AD for each of the Tanzu Application Platform default roles (app-operator, app-viewer, and app-editor) :

```sh
LOCATION="westeurope"
AKS_CLUSTER_NAME="aks-tap42"
RG_APP="rg-aks-tap-apps"
TANZU_INSTALL_DIR=tanzu
APP_NAME=tap42

aks_cluster_id=$(az aks show -n $AKS_CLUSTER_NAME -g $RG_APP --query id -o tsv)
echo "AKS cluster ID : " $aks_cluster_id

az aks get-credentials --name $AKS_CLUSTER_NAME -g $RG_APP

# Create the first example group in Azure AD for the application developers
TAP_APP_OPERATOR_ID=$(az ad group create --display-name tap-app-operator --mail-nickname tap-app-operator --query id -o tsv)
echo "TAP APP OPERATOR GROUP ID: " $TAP_APP_OPERATOR_ID
TAP_APP_OPERATOR_ID=$(az ad group show --group tap-app-operator --query id -o tsv | tr -d '\r')
az role assignment create --assignee $TAP_APP_OPERATOR_ID --role "Azure Kubernetes Service Cluster User Role" --scope $aks_cluster_id

TAP_APP_VIEWER_ID=$(az ad group create --display-name tap-app-viewer --mail-nickname tap-app-viewer --query id -o tsv)
echo "TAP APP OPERATOR GROUP ID: " $TAP_APP_VIEWER_ID
TAP_APP_VIEWER_ID=$(az ad group show --group tap-app-viewer --query id -o tsv | tr -d '\r')
az role assignment create --assignee $TAP_APP_VIEWER_ID --role "Azure Kubernetes Service Cluster User Role" --scope $aks_cluster_id

TAP_APP_EDITOR_ID=$(az ad group create --display-name tap-app-edittor --mail-nickname tap-app-edittor --query id -o tsv)
echo "TAP APP EDITOR GROUP ID: " $TAP_APP_EDITOR_ID
TAP_APP_EDITOR_ID=$(az ad group show --group tap-app-edittor --query id -o tsv | tr -d '\r')
az role assignment create --assignee $TAP_APP_EDITOR_ID --role "Azure Kubernetes Service Cluster User Role" --scope $aks_cluster_id
```


Install the Tanzu Application Platform RBAC CLI plug-in
Download the Tanzu Application Platform RBAC CLI plug-in tar.gz file from [Tanzu Network](https://network.tanzu.vmware.com/products/tap-auth)

```sh
tar -zxvf tanzu-auth-plugin_1.1.0-beta.1.tar.gz
tanzu plugin install rbac --local linux-amd64
```


```sh

# Which NS ??? ==> workaround : allow to ALL NS, not good from a security perspective
# tanzu rbac binding add -g OBJECT-ID -r TAP-ROLE -n NAMESPACE

TAP_NAMESPACE=tanzu
DEV_NAMESPACE=tap-dev
TAP_INSTALL_NAMESPACE=tap-install
KAPP_NAMESPACE=kapp-controller

AAD_ADM_GRP="AKS TAP Admin Group"
aad_admin_group_object_id=$(az ad group show -g "$AAD_ADM_GRP" --query id -o tsv)
echo "aad_admin_group_object_id" : $aad_admin_group_object_id

tanzu rbac binding add -g $aad_admin_group_object_id -r app-operator -n $TAP_INSTALL_NAMESPACE
tanzu rbac binding add -g $aad_admin_group_object_id -r app-viewer -n $TAP_INSTALL_NAMESPACE
tanzu rbac binding add -g $aad_admin_group_object_id -r app-editor -n $TAP_INSTALL_NAMESPACE
tanzu rbac binding add -g $aad_admin_group_object_id -r service-operator -n $TAP_INSTALL_NAMESPACE

# Only TAP default roles are support [app-viewer, app-editor, app-operator, service-operator]
tanzu rbac binding add -g $TAP_APP_OPERATOR_ID -r app-operator -n $TAP_NAMESPACE
tanzu rbac binding add -g $TAP_APP_VIEWER_ID -r app-viewer -n $DEV_NAMESPACE

tanzu rbac binding add -g $TAP_APP_EDITOR_ID -r app-editor -n $DEV_NAMESPACE

tanzu rbac binding add -g $TAP_APP_EDITOR_ID -r app-editor -n $KAPP_NAMESPACE

# tanzu rbac binding add -g $TAP_APP_OPERATOR_ID -r app-operator -A
# tanzu rbac binding add -g $TAP_APP_VIEWER_ID -r app-viewer -A
# tanzu rbac binding add -g $TAP_APP_EDITOR_ID -r app-edittor -A

# You must use one of the verified domain names in your organization ex: foo@xxxEnvMCAP123456.onmicrosoft.com
USR_ID=$(az account show --query user.name -o tsv)

APPDEV_ID=$(az ad group show  --group appdev-${APP_NAME} --query id -o tsv)
echo "APPDEV GROUP ID: " $APPDEV_ID

OPSSRE_ID=$(az ad group show --group opssre-${APP_NAME}  --query id -o tsv)
echo "OPSSRE GROUP ID: " $OPSSRE_ID


tanzu rbac binding add --user $USR_ID --role app-operator --namespace $DEV_NAMESPACE
tanzu rbac binding add --user $USR_ID --role app-viewer --namespace $DEV_NAMESPACE
tanzu rbac binding add --user $USR_ID --role app-editor --namespace $DEV_NAMESPACE
tanzu rbac binding add --user $USR_ID --role service-operator --namespace $DEV_NAMESPACE

tanzu rbac binding add --group $APPDEV_ID  --role app-operator --namespace $DEV_NAMESPACE
tanzu rbac binding add --group $APPDEV_ID  --role app-viewer --namespace $DEV_NAMESPACE
tanzu rbac binding add --group $APPDEV_ID  --role app-editor --namespace $DEV_NAMESPACE

tanzu rbac binding add --group $OPSSRE_ID --role app-operator --namespace $DEV_NAMESPACE
tanzu rbac binding add --group $OPSSRE_ID --role app-viewer --namespace $DEV_NAMESPACE
tanzu rbac binding add --group $OPSSRE_ID --role app-editor --namespace $DEV_NAMESPACE
tanzu rbac binding add --group $OPSSRE_ID --role service-operator --namespace $DEV_NAMESPACE

tanzu rbac binding get --role app-editor --namespace user-ns



# https://backstage.io/docs/auth/microsoft/provider
# https://learn.microsoft.com/en-gb/azure/active-directory/develop/reply-url
# https://mappslearning.wordpress.com/2022/04/19/enabling-microsoft-azure-authenticator-for-tanzu-application-platform-tap/
# Register reply address for the application. : /api/auth/microsoft/handler/frame

APP_DNS_ZONE=tap-gui.tap.appinno.com

az ad app update \
    --id ${TAP_BACKSTAGE_AUTH_MICROSOFT_CLIENT_ID} \
    --web-redirect-uris "https://${APP_DNS_ZONE}/api/auth/microsoft/handler/frame"

# test from a browser:
https://tap-gui.tap.appinno.com/api/auth/microsoft
https://tap-gui.tap.appinno.com/api/auth/github


envsubst < ./$TANZU_INSTALL_DIR/tap-values.yml > ./$TANZU_INSTALL_DIR/deploy/tap-values.yml
echo "Cheking folder " ./$TANZU_INSTALL_DIR/deploy
ls -al ./$TANZU_INSTALL_DIR/deploy
cat ./$TANZU_INSTALL_DIR/deploy/tap-values.yml

```

Access to the TAP GUI: https://tap-gui.tap.<Your Custom Domain>

Ex: https://tap-gui.tap.appinno.com/


## TAP-values Troubleshoot

To update TAP-values run the Workflow [.github/workflows/update-tap-values.yml](.github/workflows/update-tap-values.yml) the command below :

```sh
TANZU_INSTALL_DIR=tanzu
TAP_INSTALL_NAMESPACE=tap-install

tanzu package installed update tap -p tap.tanzu.vmware.com -v $TAP_VERSION --values-file ${TANZU_INSTALL_DIR}/deploy/tap-values.yml -n ${TAP_INSTALL_NAMESPACE}

tanzu package installed list -A
```

To check the TAP-GUI final configiuration inside the AKS cluster : 

```sh
kubernetes describe pod server-6d88c74f7d-mfrm7 -n tap-gui
kubernetes logs server-6d88c74f7d-mfrm7 -n tap-gui
kubernetes get secrets  -n tap-gui
kubernetes get secret app-config-ver-1 -n tap-gui
kubernetes get secret app-config-ver-1 -n tap-gui -o jsonpath='{.data}' > app-config.encoded
cat app-config.encoded | base64 --decode > app-config.yaml

```


# Cost savings - Green-IT

```sh
LOCATION="westeurope"
AKS_CLUSTER_NAME="aks-tap42"
RG_APP="rg-aks-tap-apps"

az aks nodepool stop --nodepool-name tapnodepool  --cluster-name $AKS_CLUSTER_NAMEKSCluster -g $RG_APP
az aks nodepool start --nodepool-name tapnodepool  --cluster-name $AKS_CLUSTER_NAMEKSCluster -g $RG_APP

az aks stop --cluster-name $AKS_CLUSTER_NAMEKSCluster -g $RG_APP
az aks start --cluster-name $AKS_CLUSTER_NAMEKSCluster -g $RG_APP

```

# Contributing

The [issue tracker](https://github.com/ezYakaEagle442/azure-tanzu-application-platform/issues) is the preferred channel for bug reports, features requests and submitting pull requests.

For pull requests, editor preferences are available in the [editor config](.editorconfig) for easy use in common text editors. Read more and download plugins at <http://editorconfig.org>.


# Credits
[https://github.com/ezYakaEagle442/azure-tanzu-application-platform](https://github.com/ezYakaEagle442/azure-tanzu-application-platform) has been forked from [https://github.com/ezYakaEagle442/aks-java-petclinic-mic-srv](https://github.com/ezYakaEagle442/aks-java-petclinic-mic-srv), itself already forked from [https://github.com/spring-petclinic/spring-petclinic-microservices](https://github.com/spring-petclinic/spring-petclinic-microservices)

## Note regarding GitHub Forks
It is not possible to [fork twice a repository using the same user account.](https://github.community/t/alternatives-to-forking-into-the-same-account/10200)
However you can [duplicate a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/duplicating-a-repository)

This repo [https://github.com/ezYakaEagle442/azure-tanzu-application-platform](https://github.com/ezYakaEagle442/azure-tanzu-application-platform) has been duplicated from [https://github.com/spring-petclinic/spring-petclinic-microservices](https://github.com/spring-petclinic/spring-petclinic-microservices)


## K8S Tips


```sh
  source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
  echo "source <(kubectl completion bash)" >> ~/.bashrc 
  alias k=kubectl
  complete -F __start_kubectl k

  alias kn='kubectl config set-context --current --namespace '

  export gen="--dry-run=client -o yaml"

  alias kp="kubectl get pods -o wide"
  alias kd="kubectl get deployment -o wide"
  alias ks="kubectl get svc -o wide"
  alias kno="kubectl get nodes -o wide"

  alias kdp="kubectl describe pod"
  alias kdd="kubectl describe deployment"
  alias kds="kubectl describe service"

  vi ~/.vimrc
  set ts=2 sw=2
  . ~/.vimrc
``

