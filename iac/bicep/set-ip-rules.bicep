@maxLength(20)
// to get a unique name each time ==> param appName string = 'demo${uniqueString(resourceGroup().id, deployment().name)}'
param appName string = 'tap${uniqueString(resourceGroup().id)}'
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
param mySQLServerName string = 'petcliaks'

@description('The PostgreSQL DB Admin Login.')
param postgreSQLadministratorLogin string = 'pg_adm'

@description('The PostgreSQL server name')
param postgreSQLServerName string = appName

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
    mySQLadministratorLogin: mySQLadministratorLogin
    mySQLadministratorLoginPassword: kv.getSecret('SPRING-DATASOURCE-PASSWORD')
    k8sOutboundPubIP: ipRules[0]
  }
}

module postgresqldb './modules/pg/postgresql.bicep' = {
  name: 'postgresqldb'
  params: {
    appName: appName
    location: location
    postgreSQLServerName: postgreSQLServerName
    postgreSQLadministratorLogin: postgreSQLadministratorLogin 
    postgreSQLadministratorLoginPassword: kv.getSecret('PG-ADM-PWD')
    k8sOutboundPubIP: ipRules[0]
  }
}
