
/* https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli#inline-parameters 
vim arrayContent.json
[
  "42.42.42.42"
]

az deployment group create --name postgresql -f ./iac/bicep/modules/pg/postgresql.bicep -g rg-aks-tap-apps \
-p appName=tap42424242 -p location=westeurope -p postgreSQLadministratorLogin=pgs_adm \
-p postgreSQLServerName=tap42424242 -p dbName=tap -p databaseSkuName=Standard_B1ms -p databaseSkuTier=Burstable -p postgreSQLVersion=14 \
-p charset=utf8 -p collation=fr_FR.utf8 \
-p k8sOutboundPubIP="42.42.42.42" \
-p postgreSQLadministratorLoginPassword=xxx
*/


@description('A UNIQUE name')
@maxLength(20)
param appName string = 'tap${uniqueString(resourceGroup().id, subscription().id)}'

@description('The location of the DB.')
param location string = resourceGroup().location

@description('The PostgreSQL DB Admin Login. IMPORTANT: username can not start with prefix "pg_" which is reserved, ex: pg_adm would fails in Bicep. Admin login name cannot be azure_superuser, azuresu, azure_pg_admin, sa, admin, administrator, root, guest, dbmanager, loginmanager, dbo, information_schema, sys, db_accessadmin, db_backupoperator, db_datareader, db_datawriter, db_ddladmin, db_denydatareader, db_denydatawriter, db_owner, db_securityadmin, public')
param postgreSQLadministratorLogin string = 'pgs_adm'

@secure()
@minLength(8)
@description('The PostgreSQL DB Admin Password.')
param postgreSQLadministratorLoginPassword string

@description('The PostgreSQL server name')
param postgreSQLServerName string = appName

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

@description('PostgreSQL version. See https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-supported-versions')
@allowed([
  '14'
  '13'
  '12'
  '11'
])
param postgreSQLVersion string = '13' // https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-supported-versions


@description('The PostgreSQL DB name.')
param dbName string = 'tap'

param charset string = 'utf8'
param collation string = 'fr_FR.utf8' // select * from pg_collation ;

// https://learn.microsoft.com/en-us/azure/templates/microsoft.dbforpostgresql/flexibleservers?pivots=deployment-language-bicep
resource PostgreSQLserver 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
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
output PostgreSQLServerName string = PostgreSQLserver.name
output PostgreSQLFQDN string = PostgreSQLserver.properties.fullyQualifiedDomainName
output PostgreSQLUser string = PostgreSQLserver.properties.administratorLogin


 // Allow AKS
 resource fwRuleAllowAKS 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-12-01' = {
  name: 'Allow-AKS-OutboundPubIP'
  parent: PostgreSQLserver
  properties: {
    startIpAddress: k8sOutboundPubIP
    endIpAddress: k8sOutboundPubIP
  }
}

output fwRuleAllowAKSResourceID string = fwRuleAllowAKS.id
output fwRuleAllowAKSName string = fwRuleAllowAKS.name

resource PostgreSQLDB 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = {
  name: dbName
  parent: PostgreSQLserver
  properties: {
    charset: charset
    collation: collation
  }
}

output PostgreSQLDBResourceID string = PostgreSQLDB.id
output PostgreSQLDBName string = PostgreSQLDB.name
