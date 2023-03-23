@maxLength(20)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'tap${uniqueString(resourceGroup().id, subscription().id)}'

@description('The name of the ACR, must be UNIQUE. The name must contain only alphanumeric characters, be globally unique, and between 5 and 50 characters in length.')
param acrName string = appName

param location string = resourceGroup().location

param dnsPrefix string = 'tanzu-${appName}'
param clusterName string = 'aks-${appName}'
param aksVersion string = '1.24.6'
param MCnodeRG string = 'rg-MC-${appName}'
param logAnalyticsWorkspaceName string = 'log-${appName}'
param vnetName string = 'vnet-aks'

@description('The Admin Group Object IDs to use for AAD Integration.')
param adminGroupObjectIDs string = '4242-4242-4242-4242'

@description('AKS Cluster UserAssigned Managed Identity name. Character limit: 3-128 Valid characters: Alphanumerics, hyphens, and underscores')
param aksIdentityName string = 'id-aks-${appName}-cluster-dev-${location}-101'

@description('The AKS SSH public key')
@secure()
param sshPublicKey string

@description('IP ranges string Array allowed to call the AKS API server, specified in CIDR format, e.g. 137.117.106.88/29. see https://learn.microsoft.com/en-us/azure/aks/api-server-authorized-ip-ranges')
param authorizedIPRanges array = []
  
@description('The AKS Cluster Admin Username')
param aksAdminUserName string = 'tap-admin'

resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing= {
  name: vnetName
}

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-secrets
module aks './modules/aks/aks.bicep' = {
  name: 'aks'
  // scope: resourceGroup(rg.name)
  params: {
    appName: appName
    clusterName: clusterName
    k8sVersion: aksVersion
    location: location
    nodeRG: MCnodeRG
    subnetID: vnet.properties.subnets[0].id
    dnsPrefix: dnsPrefix
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    aksIdentityName: aksIdentityName
    sshPublicKey: sshPublicKey
    aksAdminUserName: aksAdminUserName
    authorizedIPRanges: authorizedIPRanges
    adminGroupObjectIDs: [adminGroupObjectIDs] 
    //serverAppID: aadServerAppID
    //serverAppSecret: aadServerAppSecret
    //clientAppID: aadClientAppID
    //enableAzureRBAC: aadEnableRBAC
  }
}

output aksId string = aks.outputs.aksId
output aksName string = aks.outputs.aksName
output controlPlaneFQDN string = aks.outputs.controlPlaneFQDN
// https://github.com/Azure/azure-rest-api-specs/issues/17563
output kubeletIdentity string = aks.outputs.kubeletIdentity
output keyVaultAddOnIdentity string = aks.outputs.keyVaultAddOnIdentity
output spnClientId string = aks.outputs.spnClientId
output aksOutboundType string = aks.outputs.aksOutboundType
// The default number of managed outbound public IPs is 1.
// https://learn.microsoft.com/en-us/azure/aks/load-balancer-standard#scale-the-number-of-managed-outbound-public-ips
output aksEffectiveOutboundIPs array = aks.outputs.aksEffectiveOutboundIPs
output aksManagedOutboundIPsCount int = aks.outputs.aksManagedOutboundIPsCount


module attachacr './modules/aks/attach-acr.bicep' = {
  name: 'attach-acr'
  params: {
    appName: appName
    acrName: acrName
    aksClusterPrincipalId: aks.outputs.kubeletIdentity
  }
  dependsOn: [
    aks
  ]
}
