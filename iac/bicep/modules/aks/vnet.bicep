param vnetName string = 'vnet-aks'
param vnetCidr string = '172.16.0.0/16'
param aksSubnetCidr string = '172.16.0.0/21'
param aksSubnetName string = 'snet-aks'

param location string = resourceGroup().location

var aksSubnet = {
  name: aksSubnetName
  cidr: aksSubnetCidr
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetCidr
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: aksSubnet.name
        properties: {
          addressPrefix: aksSubnet.cidr
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.KeyVault'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.Storage'
              locations: [
                '*'
              ]
            } 
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

output vnetId string = vnet.id
output aksSubnetId string = vnet.properties.subnets[0].id
output aksSubnetAddressPrefix string = vnet.properties.subnets[0].properties.addressPrefix
