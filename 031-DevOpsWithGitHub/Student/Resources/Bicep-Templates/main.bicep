targetScope = 'subscription'

param location string = 'northeurope'
param prefix string = 'duck'

param webAppName string = '${prefix}devops-dev'
param hostingPlanName string = '${prefix}devops-asp'
param appInsightsName string = '${prefix}devops-ai'
param sku string = 'S1'
param registryName string = '${prefix}devopsreg'
param imageName string = '${prefix}devopsimage'
param registrySku string = 'Standard'
param startupCommand string = ''


resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefix}-rg'
  location: location
}

module azresources 'container-webapp-template.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'test'
  params:  {
   location: location
   webAppName: webAppName
   appInsightsName: appInsightsName
   hostingPlanName: hostingPlanName
   sku: sku
   registryName: registryName
   imageName: imageName
   registrySku: registrySku
   startupCommand: startupCommand
   prefix: prefix
  }
}
