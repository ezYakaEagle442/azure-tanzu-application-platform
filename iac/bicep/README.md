# AKS


In the [Bicep parameter file](./parameters-pre-req.json) :
- set your laptop/dev station IP adress to the field "clientIPAddress"
- Instead of putting a secure value (like a password) directly in your Bicep file or parameter file, you can retrieve the value from an Azure Key Vault during a deployment. When a module expects a string parameter with secure:true modifier, you can use the getSecret function to obtain a key vault secret. The value is never exposed because you only reference its key vault ID.


FYI, if you want to check the services available per locations :
```sh
az provider list --output table

az provider show -n  Microsoft.ContainerService --query  "resourceTypes[?resourceType == 'managedClusters']".locations | jq '.[0]' | jq 'length'
az provider show -n  Microsoft.AppPlatform --query  "resourceTypes[?resourceType == 'Spring']".locations | jq '.[0]' | jq 'length'
az provider show -n  Microsoft.App --query  "resourceTypes[?resourceType == 'managedEnvironments']".locations | jq '.[0]' | jq 'length’
az provider show -n  Microsoft.App --query  "resourceTypes[?resourceType == 'connectedEnvironments']".locations | jq '.[0]' | jq 'length'

```


```sh
LOCATION=westeurope
az group create --name rg-kv-tanzu101 --location $LOCATION
az group create --name rg-aks-tap-apps --location $LOCATION

```

Note: you can Run a Bicep script to debug and output the results to Azure Storage, see :
-  [doc](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-bicep#sample-bicep-files)
- [https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?pivots=deployment-language-bicep](https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?pivots=deployment-language-bicep)