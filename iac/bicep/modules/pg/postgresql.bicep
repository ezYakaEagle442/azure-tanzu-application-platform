
@description('A UNIQUE name')
@maxLength(20)
param appName string = 'tap${uniqueString(resourceGroup().id)}'

@description('The location of the DB.')
param location string = resourceGroup().location

@description('The PostgreSQL DB Admin Login.')
param postgreSQLadministratorLogin string = 'pg_adm'

@secure()
@description('The PostgreSQL DB Admin Password.')
param postgreSQLadministratorLoginPassword string

@description('The PostgreSQL server name')
param postgreSQLServerName string = 'tanzu${appName}'

@description('AKS Outbound Public IP')
param k8sOutboundPubIP string = '0.0.0.0'

// https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-deploy-on-azure-free-account
@description('Azure database for PostgreSQL SKU')
@allowed([
  'Standard_D4s_v3'
  'Standard_D2s_v3'
  'Standard_B1ms'
])
param databaseSkuName string = 'Standard_D2s_v3' //  'GP_Gen5_2' for single server

@description('Azure database for PostgreSQL pricing tier')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param databaseSkuTier string = 'GeneralPurpose'

@description('PostgreSQL version')
@allowed([
  '14'
  '13'
  '12'
  '11'
])
param postgreSQLVersion string = '13' // https://docs.microsoft.com/en-us/azure/PostgreSQL/concepts-supported-versions

// https://learn.microsoft.com/en-us/azure/templates/microsoft.dbforpostgresql/flexibleservers?pivots=deployment-language-bicep
resource PostgreSQLserver 'Microsoft.DBforPostgreSQL/flexibleServers@2022-03-08-preview' = {
  location: location
  name: postgreSQLServerName
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
  }
  properties: {
    administratorLogin: postgreSQLadministratorLogin
    administratorLoginPassword: postgreSQLadministratorLoginPassword
    // availabilityZone: '1'
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    //createMode: 'Default'
    highAvailability: {
      mode: 'Disabled'
    }
    replicationRole: 'None'
    version: postgreSQLVersion
    storage: {
      storageSizeGB: 32
    }
  }
  
}

output PostgreSQLResourceID string = PostgreSQLserver.id


 // Allow AKS
 resource fwRuleAllowAKS 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-03-08-preview' = {
  name: 'Allow-AKS-OutboundPubIP'
  parent: PostgreSQLserver
  properties: {
    startIpAddress: k8sOutboundPubIP
    endIpAddress: k8sOutboundPubIP
  }
}
