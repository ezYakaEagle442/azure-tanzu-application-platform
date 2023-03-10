param appName string = 'tap${uniqueString(resourceGroup().id, subscription().id)}'

param logAnalyticsWorkspaceName string = 'log-${appName}'
param location string = 'westeurope'

// https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces?tabs=bicep
resource logAnalyticsWorkspace  'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
