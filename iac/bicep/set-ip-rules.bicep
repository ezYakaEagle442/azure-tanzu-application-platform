@maxLength(20)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'tap${uniqueString(resourceGroup().id, subscription().id)}'
param location string = 'westeurope'

@description('The Azure Active Directory tenant ID that should be used for authenticating requests to the Key Vault.')
param tenantId string = subscription().tenantId

@maxLength(24)
@description('The name of the KV, must be UNIQUE. A vault name must be between 3-24 alphanumeric characters.')
param kvName string = 'kv-${appName}'

@description('The name of the KV RG')
param kvRGName string

@description('The VNet rules to whitelist for the KV')
param  vNetRules array = []
@description('The IP rules to whitelist for the KV & MySQL')
param  ipRules array = []

@description('The MySQL DB Admin Login.')
param mySQLadministratorLogin string = 'mys_adm'

@description('The MySQL server name')
param mySQLServerName string = appName

@description('The MySQL DB name.')
param mySqlDbName string = 'petclinic'

param mySqlCharset string = 'utf8'

@allowed( [
  'utf8_general_ci'

])
param mySqlCollation string = 'utf8_general_ci' // SELECT @@character_set_database, @@collation_database;

@description('The PostgreSQL DB Admin Login. IMPORTANT: username can not start with prefix "pg_" which is reserved, ex: pg_adm would fails in Bicep. Admin login name cannot be azure_superuser, azuresu, azure_pg_admin, sa, admin, administrator, root, guest, dbmanager, loginmanager, dbo, information_schema, sys, db_accessadmin, db_backupoperator, db_datareader, db_datawriter, db_ddladmin, db_denydatareader, db_denydatawriter, db_owner, db_securityadmin, public')
param postgreSQLadministratorLogin string = 'pgs_adm'

@description('The PostgreSQL server name')
param postgreSQLServerName string = appName

@description('The PostgreSQL DB name.')
param pgDbName string = 'tap'

param pgCharset string = 'utf8'
param pgCollation string = 'fr_FR.utf8' // select * from pg_collation ;

@description('The Storage Account name')
param azureStorageName string = 'sta${appName}'

@description('The BLOB Storage Container name')
param blobContainerName string = '${appName}-blob'

resource kvRG 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: kvRGName
  scope: subscription()
}


// see https://github.com/microsoft/azure-container-apps/issues/469
// Now KV must Allow AKS OutboundPubIP in the IP rules ...
// Must allow AKS to access Existing KV

module kvsetiprules './modules/kv/kv.bicep' = {
  name: 'kv-set-iprules'
  scope: kvRG
  params: {
    kvName: kvName
    location: location
    ipRules: ipRules
    vNetRules: vNetRules
  }
}

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
  scope: kvRG
}  

module mysqlPub './modules/mysql/mysql.bicep' = {
  name: 'mysqldbpub'
  params: {
    appName: appName
    location: location
    mySQLServerName: mySQLServerName
    dbName: mySqlDbName
    mySQLadministratorLogin: mySQLadministratorLogin
    mySQLadministratorLoginPassword: kv.getSecret('SPRING-DATASOURCE-PASSWORD')
    k8sOutboundPubIP: ipRules[0]
    charset: mySqlCharset
    collation: mySqlCollation
  }
}

module postgresqldb './modules/pg/postgresql.bicep' = {
  name: 'postgresqldb'
  params: {
    appName: appName
    location: location
    postgreSQLServerName: postgreSQLServerName
    dbName: pgDbName
    postgreSQLadministratorLogin: postgreSQLadministratorLogin 
    postgreSQLadministratorLoginPassword: kv.getSecret('PG-ADM-PWD')
    k8sOutboundPubIP: ipRules[0]
    charset: pgCharset
    collation: pgCollation
  }
}

module storage './modules/aks/storage.bicep' = {
  name: 'storage'
  params: {
    appName: appName
    location: location
    vNetRules: vNetRules
    ipRules: ipRules[0]
    azureStorageName: azureStorageName
    blobContainerName: blobContainerName
  }
}
