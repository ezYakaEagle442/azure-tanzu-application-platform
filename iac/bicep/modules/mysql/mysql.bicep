
@description('A UNIQUE name')
@maxLength(20)
param appName string = 'tap${uniqueString(resourceGroup().id, subscription().id)}'

@description('The location of the MySQL DB.')
param location string = resourceGroup().location

@description('The MySQL DB Admin Login.')
param mySQLadministratorLogin string = 'mys_adm'

@secure()
@minLength(8)
@description('The MySQL DB Admin Password.')
param mySQLadministratorLoginPassword string

@description('The MySQL server name')
param mySQLServerName string = appName

@description('The MySQL DB name.')
param dbName string = 'petclinic'

@description('AKS Outbound Public IP')
param k8sOutboundPubIP string = '0.0.0.0'

// https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-deploy-on-azure-free-account
@description('Azure Database for MySQL SKU')
@allowed([
  'Standard_D4s_v3'
  'Standard_D2s_v3'
  'Standard_B1ms'
])
param databaseSkuName string = 'Standard_B1ms' //  'GP_Gen5_2' for single server

@description('Azure Database for MySQL pricing tier')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param databaseSkuTier string = 'Burstable'

@description('MySQL version see https://learn.microsoft.com/en-us/azure/mysql/concepts-version-policy')
@allowed([
  '8.0.21'
  '8.0.28'
  '5.7'
])
param mySqlVersion string = '5.7' // https://docs.microsoft.com/en-us/azure/mysql/concepts-supported-versions

param charset string = 'utf8'

@allowed( [
  'utf8_general_ci'

])
param collation string = 'utf8_general_ci' // SELECT @@character_set_database, @@collation_database;

resource mysqlserver 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  location: location
  name: mySQLServerName
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
  }
  properties: {
    administratorLogin: mySQLadministratorLogin
    administratorLoginPassword: mySQLadministratorLoginPassword
    // availabilityZone: '1'
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    createMode: 'Default'
    highAvailability: {
      mode: 'Disabled'
    }
    replicationRole: 'None'
    version: mySqlVersion
  }
}

output mySQLResourceID string = mysqlserver.id
output mySQLServerName string = mysqlserver.name
output mySQLServerFQDN string = mysqlserver.properties.fullyQualifiedDomainName


resource mysqlDB 'Microsoft.DBforMySQL/flexibleServers/databases@2021-12-01-preview' = {
  name: dbName
  parent: mysqlserver
  properties: {
    charset: charset
    collation: collation
  }
}

output mysqlDBResourceId string = mysqlDB.id
output mysqlDBName string = mysqlDB.name

 // Allow AKS
 resource fwRuleAllowAKS 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-12-01-preview' = {
  name: 'Allow-AKS-OutboundPubIP'
  parent: mysqlserver
  properties: {
    startIpAddress: k8sOutboundPubIP
    endIpAddress: k8sOutboundPubIP
  }
}

output fwRuleAllowAKSResourceId string = fwRuleAllowAKS.id
output fwRuleAllowAKSName string = fwRuleAllowAKS.name
