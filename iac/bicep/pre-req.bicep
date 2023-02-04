// Check the REST API : https://learn.microsoft.com/en-us/rest/api/aks/managed-clusters

@maxLength(20)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'tap${uniqueString(resourceGroup().id)}'
param location string = 'westeurope'
param acrName string = 'acr${appName}'

@description('The Log Analytics workspace name used by the AKS cluster')
param logAnalyticsWorkspaceName string = 'log-${appName}'

@allowed([
  'log-analytics'
])
param logDestination string = 'log-analytics'

param appInsightsName string = 'appi-${appName}'

@description('Should the service be deployed to a Corporate VNet ?')
param deployToVNet bool = false

param vnetName string = 'vnet-aks'
param vnetCidr string = '172.16.0.0/16'
param aksSubnetCidr string = '172.16.1.0/24'
param aksSubnetName string = 'snet-aks'

@description('The MySQL DB Admin Login.')
param mySQLadministratorLogin string = 'mys_adm'

@secure()
@description('The MySQL DB Admin Password.')
param mySQLadministratorLoginPassword string

@description('The MySQL server name')
param mySQLServerName string = appName

@description('The PostgreSQL DB Admin Login.')
param postgreSQLadministratorLogin string = 'pg_adm'

@secure()
@description('The PostgreSQL DB Admin Password.')
param postgreSQLadministratorLoginPassword string

@description('The PostgreSQL server name')
param postgreSQLServerName string = appName

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.')
param tenantId string = subscription().tenantId

@description('The Storage Account name')
param azureStorageName string = 'staks${appName}'

@description('The BLOB Storage service name')
param azureBlobServiceName string = 'default'

@description('The BLOB Storage Container name')
param blobContainerName string = '${appName}-blob'

@description('The GitHub Runner Service Principal Id')
param ghRunnerSpnPrincipalId string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?tabs=bicep
resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceCustomerId string = logAnalyticsWorkspace.properties.customerId

// https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/components?tabs=bicep
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: { 
    Application_Type: 'web'
    //Flow_Type: 'Bluefield'    
    //ImmediatePurgeDataOn30Days: true // "ImmediatePurgeDataOn30Days cannot be set on current api-version"
    //RetentionInDays: 30
    IngestionMode: 'LogAnalytics' // Cannot set ApplicationInsightsWithDiagnosticSettings as IngestionMode on consolidated application 
    Request_Source: 'rest'
    SamplingPercentage: 20
    WorkspaceResourceId: logAnalyticsWorkspace.id    
  }
}
output appInsightsId string = appInsights.id
output appInsightsConnectionString string = appInsights.properties.ConnectionString
// output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey

module ACR './modules/aks/acr.bicep' = {
  name: acrName
  params: {
    appName: appName
    acrName: acrName
    location: location
    networkRuleSetCidr: vnetCidr
  }
}

module identities './modules/aks/identity.bicep' = {
  name: 'aks-identities'
  params: {
    location: location
  }
}

module vnet './modules/aks/vnet.bicep' = {
  name: 'vnet-aks'
  // scope: resourceGroup(rg.name)
  params: {
    location: location
     vnetName: vnetName
     aksSubnetName: aksSubnetName
     vnetCidr: vnetCidr
     aksSubnetCidr: aksSubnetCidr
  }   
}

var vNetRules = [
  {
    'id': vnet.outputs.aksSubnetId
    'ignoreMissingVnetServiceEndpoint': false
  }
]

// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scope-extension-resources
module roleAssignments './modules/aks/roleAssignments.bicep' = {
  name: 'role-assignments'
  params: {
    aksClusterPrincipalId: identities.outputs.aksIdentityPrincipalId
    networkRoleType: 'NetworkContributor'
    vnetName: vnetName
    subnetName: aksSubnetName
  }
}

module mysql './modules/mysql/mysql.bicep' = {
  name: 'mysqldb'
  params: {
    appName: appName
    location: location
    mySQLServerName: mySQLServerName
    mySQLadministratorLogin: mySQLadministratorLogin
    mySQLadministratorLoginPassword: mySQLadministratorLoginPassword
    // The default number of managed outbound public IPs is 1.
    // https://learn.microsoft.com/en-us/azure/aks/load-balancer-standard#scale-the-number-of-managed-outbound-public-ips
  }
}

/* 
module postgresqldb './modules/pg/postgresql.bicep' = {
  name: 'postgresqldb'
  params: {
    appName: appName
    location: location
    postgreSQLServerName: postgreSQLServerName
    postgreSQLadministratorLogin: postgreSQLadministratorLogin 
    postgreSQLadministratorLoginPassword: postgreSQLadministratorLoginPassword
  }
}
*/

module storage './modules/aks/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    appName: appName
    blobContainerName: blobContainerName
    azureBlobServiceName: azureBlobServiceName
    azureStorageName: azureStorageName
    ghRunnerSpnPrincipalId: ghRunnerSpnPrincipalId
  }
  dependsOn: [
    identities
  ] 
}
