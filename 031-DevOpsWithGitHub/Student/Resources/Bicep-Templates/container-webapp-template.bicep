param location string = 'northeurope'
param prefix string = 'duck'

param webAppName string = '${prefix}devops-dev'
param hostingPlanName string = '${prefix}devops-asp'
param appInsightsName string = '${prefix}devops-ai'
param sku string = 'S1'
param workspaceName string = '${prefix}devops-la'
param registryName string = '${prefix}devopsreg'
param imageName string = '${prefix}devopsimage'
param registrySku string = 'Standard'
param startupCommand string = ''

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  tags: {
    'hidden-related:/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${hostingPlanName}': 'empty'
    'hidden-link:/app-insights-resource-id': appInsights.id
  }
  properties: {

    siteConfig: {

      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${registry.properties.loginServer}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: listCredentials('Microsoft.ContainerRegistry/registries/${registryName}', '2017-10-01').username
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: listCredentials('Microsoft.ContainerRegistry/registries/${registryName}', '2017-10-01').passwords[0].value
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'DiagnosticServices_EXTENSION_VERSION'
          value: '~3'
        }
      ]

      appCommandLine: startupCommand
      linuxFxVersion: 'DOCKER|${registry.properties.loginServer}/${imageName}'

    }
    serverFarmId: hostingPlan.id
  }
}

resource registry 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  sku: {
    name: registrySku
  }
  name: registryName
  location: location
  properties: {
    adminUserEnabled: true
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  sku: {
    tier: first(skip(split(sku, ' '), 1))
    name: first(split(sku, ' '))
  }
  kind: 'linux'
  name: hostingPlanName

  location: location
  properties: {
    reserved: true
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  kind: 'web'
  location: location
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 120
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}
