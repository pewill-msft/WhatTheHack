
param location string = 'westeurope'
param prefix string = 'duck'

param webAppName string = '${prefix}devops-dev'
param hostingPlanName string = '${prefix}devops-asp'
param appInsightsName string = '${prefix}devops-ai'
param sku string = 'S1'
param registryName string = '${prefix}devopsreg'
param imageName string = '${prefix}devopsimage'
param registrySku string = 'Standard'
param startupCommand string = ''

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  tags: {
    'hidden-related:/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${hostingPlanName}': 'empty'
  }
  properties: {

    siteConfig: {
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

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
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
resource appServiceLogging 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webApp
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    DiagnosticServices_EXTENSION_VERSION: '~3'
    DOCKER_REGISTRY_SERVER_URL: 'https://${registry.properties.loginServer}'
    DOCKER_REGISTRY_SERVER_USERNAME: listCredentials('Microsoft.ContainerRegistry/registries/${registryName}', '2017-10-01').username
    DOCKER_REGISTRY_SERVER_PASSWORD: listCredentials('Microsoft.ContainerRegistry/registries/${registryName}', '2017-10-01').passwords[0].value
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'

  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  kind: 'web'
  location: location
  tags: {
    'hidden-link:${webApp.id}': 'Resource'
  }
  properties: {
    Application_Type: 'web'
  }
}
