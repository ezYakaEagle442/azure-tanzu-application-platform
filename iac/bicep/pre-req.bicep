// Check the REST API : https://learn.microsoft.com/en-us/rest/api/aks/managed-clusters

@maxLength(20)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'tap${uniqueString(resourceGroup().id, subscription().id)}'
param location string = resourceGroup().location
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
param aksSubnetCidr string = '172.16.0.0/21'
param aksSubnetName string = 'snet-aks'

@description('The MySQL DB Admin Login.')
param mySQLadministratorLogin string = 'mys_adm'

@secure()
@description('The MySQL DB Admin Password.')
param mySQLadministratorLoginPassword string

@description('The MySQL server name')
param mySQLServerName string = appName

@description('The MySQL DB name.')
param mySqlDbName string = 'petclinic'

param mySqlCharset string = 'utf8'

@allowed( [
  'utf8_general_ci'

])
param mySqlCollation string = 'utf8_general_ci' // SELECT @@character_set_database, @@collation_database;

@description('Azure Database SKU')
@allowed([
  'Standard_D4s_v3'
  'Standard_D2s_v3'
  'Standard_B1ms'
])
param databaseSkuName string = 'Standard_B1ms' //  'GP_Gen5_2' for single server

@description('Azure Database pricing tier')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param databaseSkuTier string = 'Burstable'

@description('The PostgreSQL DB Admin Login. IMPORTANT: username can not start with prefix "pg_" which is reserved, ex: pg_adm would fails in Bicep. Admin login name cannot be azure_superuser, azuresu, azure_pg_admin, sa, admin, administrator, root, guest, dbmanager, loginmanager, dbo, information_schema, sys, db_accessadmin, db_backupoperator, db_datareader, db_datawriter, db_ddladmin, db_denydatareader, db_denydatawriter, db_owner, db_securityadmin, public')
param postgreSQLadministratorLogin string = 'pgs_adm'

@secure()
@description('The PostgreSQL DB Admin Password.')
param postgreSQLadministratorLoginPassword string

@description('The PostgreSQL server name')
param postgreSQLServerName string = appName

@description('The PostgreSQL DB name.')
param pgDbName string = 'tap'

param pgCharset string = 'utf8'
param pgCollation string = 'fr_FR.utf8' // select * from pg_collation ;

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
  name: 'acr'
  params: {
    appName: appName
    acrName: acrName
    location: location
    networkRuleSetCidr: vnetCidr
  }
}

output acrId string = ACR.outputs.acrId
output acrName string = ACR.outputs.acrName
output acrIdentity string = ACR.outputs.acrIdentity
output acrType string = ACR.outputs.acrType
output acrRegistryUrl string = ACR.outputs.acrRegistryUrl

module identities './modules/aks/identity.bicep' = {
  name: 'aks-identities'
  params: {
    location: location
    appName: appName
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
    appName: appName
    aksClusterPrincipalId: identities.outputs.aksIdentityPrincipalId
    networkRoleType: 'NetworkContributor'
    vnetName: vnetName
    subnetName: aksSubnetName
    azureStorageName: azureStorageName
    azureBlobServiceName: azureBlobServiceName
    blobContainerName: blobContainerName
    storageBlobRoleType: 'StorageBlobDataContributor'
    ghRunnerSpnPrincipalId: ghRunnerSpnPrincipalId
  }
}

module mysql './modules/mysql/mysql.bicep' = {
  name: 'mysqldb'
  params: {
    appName: appName
    location: location
    mySQLServerName: mySQLServerName
    dbName: mySqlDbName
    databaseSkuName: databaseSkuName
    databaseSkuTier: databaseSkuTier
    mySQLadministratorLogin: mySQLadministratorLogin
    mySQLadministratorLoginPassword: mySQLadministratorLoginPassword
    charset: mySqlCharset
    collation: mySqlCollation
    // The default number of managed outbound public IPs is 1.
    // https://learn.microsoft.com/en-us/azure/aks/load-balancer-standard#scale-the-number-of-managed-outbound-public-ips
  }
}

output mySQLResourceID string = mysql.outputs.mySQLResourceID
output mySQLServerName string = mysql.outputs.mySQLServerName
output mySQLServerFQDN string = mysql.outputs.mySQLServerFQDN
output mysqlDBResourceId string = mysql.outputs.mysqlDBResourceId
output mysqlDBName string = mysql.outputs.mysqlDBName

module postgresqldb './modules/pg/postgresql.bicep' = {
  name: 'postgresqldb'
  params: {
    appName: appName
    location: location
    postgreSQLServerName: postgreSQLServerName
    dbName: pgDbName
    databaseSkuName: databaseSkuName
    databaseSkuTier: databaseSkuTier    
    postgreSQLadministratorLogin: postgreSQLadministratorLogin 
    postgreSQLadministratorLoginPassword: postgreSQLadministratorLoginPassword
    charset: pgCharset
    collation: pgCollation
  }
}

output PostgreSQLResourceID string = postgresqldb.outputs.PostgreSQLResourceID
output PostgreSQLServerName string = postgresqldb.outputs.PostgreSQLServerName
output PostgreSQLFQDN string = postgresqldb.outputs.PostgreSQLFQDN
output PostgreSQLDBResourceID string = postgresqldb.outputs.PostgreSQLDBResourceID
output PostgreSQLDBName string = postgresqldb.outputs.PostgreSQLDBName

module storage './modules/aks/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    appName: appName
    blobContainerName: blobContainerName
    azureBlobServiceName: azureBlobServiceName
    azureStorageName: azureStorageName
  }
  dependsOn: [
    identities
  ] 
}

output azurestorageId string = storage.outputs.azurestorageId
output azurestorageName string = storage.outputs.azurestorageName
output azurestorageHttpEndpoint string = storage.outputs.azurestorageHttpEndpoint
output azurestorageFileEndpoint string = storage.outputs.azurestorageFileEndpoint
output azureblobserviceId string = storage.outputs.azureblobserviceId
output azureblobserviceName string = storage.outputs.azureblobserviceName
output blobcontainerId string = storage.outputs.blobcontainerId
output blobcontainerName string = storage.outputs.blobcontainerName
