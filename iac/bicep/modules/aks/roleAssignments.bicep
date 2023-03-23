@description('A UNIQUE name')
@maxLength(20)
param appName string = 'tap${uniqueString(resourceGroup().id, subscription().id)}'

param aksClusterPrincipalId string

@allowed([
  'Owner'
  'Contributor'
  'NetworkContributor'
  'Reader'
])
@description('VNet Built-in role to assign')
param networkRoleType string

param vnetName string = 'vnet-aks'
param subnetName string = 'snet-aks'

@description('The Storage Account name')
param azureStorageName string = 'sta${appName}'

@description('The BLOB Storage service name')
param azureBlobServiceName string = 'default' // '${appName}-blob-svc'

@description('The BLOB Storage Container name')
param blobContainerName string = '${appName}-blob'

@allowed([
  'StorageBlobDataContributor'
])
@description('Azure Blob Storage Built-in role to assign')
param storageBlobRoleType string = 'StorageBlobDataContributor'

param ghRunnerSpnPrincipalId string

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  name: '${vnetName}/${subnetName}'
}


// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var role = {
  Owner: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  Reader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
  NetworkContributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
  AcrPull: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
  KeyVaultAdministrator: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483'
  KeyVaultReader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/21090545-7ca7-4776-b22c-e363652d74d2'
  KeyVaultSecretsUser: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6'
  StorageBlobDataContributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}


// https://github.com/Azure/azure-quickstart-templates/blob/master/modules/Microsoft.ManagedIdentity/user-assigned-identity-role-assignment/1.0/main.bicep
// https://github.com/Azure/bicep/discussions/5276
// Assign ManagedIdentity ID to the "Network contributor" role to AKS VNet
resource AKSClusterRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksSubnet.id, networkRoleType , aksClusterPrincipalId)
  scope: aksSubnet
  properties: {
    roleDefinitionId: role[networkRoleType] // subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: aksClusterPrincipalId
    principalType: 'ServicePrincipal'
  }
}
output aksClusterRoleAssignmentId string = AKSClusterRoleAssignment.id
output aksClusterRoleAssignmentName string = AKSClusterRoleAssignment.name
output aksClusterRoleAssignmentRoleDefinitionId string = AKSClusterRoleAssignment.properties.roleDefinitionId
output aksClusterRoleAssignmentRoleUpdatedOn string = AKSClusterRoleAssignment.properties.updatedOn
output aksClusterRoleAssignmentType string = AKSClusterRoleAssignment.type

// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep
resource azurestorage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: azureStorageName
}

resource azureblobservice 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' existing = {
  name: azureBlobServiceName
  parent: azurestorage
}

// GH Runner SPN must have "Storage Blob Data Contributor" Role on the storage Account
// https://learn.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?pivots=deployment-language-bicep
resource StorageBlobDataContributorRoleAssignmentGHRunner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(azureblobservice.id, storageBlobRoleType , ghRunnerSpnPrincipalId)
  scope: azurestorage
  properties: {
    roleDefinitionId: role[storageBlobRoleType]
    principalId: ghRunnerSpnPrincipalId
    principalType: 'ServicePrincipal'
  }
}
