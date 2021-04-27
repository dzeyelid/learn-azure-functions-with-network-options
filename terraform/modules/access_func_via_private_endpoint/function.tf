locals {
  function_name                  = "func-${local.identifier_in_module}"
  private_function_dns_zone_name = "privatelink.azurewebsites.net"
}

resource "azurerm_application_insights" "for_func" {
  name                = "appi-${local.identifier_in_module}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}

resource "azurerm_app_service_plan" "main" {
  name                = local.app_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }
}

resource "azurerm_function_app" "main" {
  name                       = local.function_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.main.id
  storage_account_name       = azurerm_storage_account.for_func.name
  storage_account_access_key = azurerm_storage_account.for_func.primary_access_key
  version                    = "~3"
  https_only                 = true

  site_config {
    always_on     = true
    ftps_state    = "Disabled"
    http2_enabled = true
  }

  app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.for_func.primary_connection_string
    WEBSITE_CONTENTSHARE                     = local.function_name
    WEBSITE_CONTENTOVERVNET                  = 1
    APPINSIGHTS_INSTRUMENTATIONKEY           = azurerm_application_insights.for_func.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME                 = "dotnet"
    WEBSITE_VNET_ROUTE_ALL                   = 1
    WEBSITE_DNS_SERVER                       = "168.63.129.16"
    WEBSITE_RUN_FROM_PACKAGE                 = var.function_package_url
    TargetHost                               = regex("^https://(?P<host>[\\d\\w.-]+):443/$", azurerm_cosmosdb_account.main.endpoint).host
  }

  depends_on = [
    azurerm_private_endpoint.for_func_blob,
  ]
}

resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id = azurerm_function_app.main.id
  subnet_id      = azurerm_subnet.for_func.id
}

#------------------------------------------------------------------------------
# Azure DNS Private Zone
#------------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "for_func" {
  name                = local.private_function_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
}

#------------------------------------------------------------------------------
# Private endpoint
#------------------------------------------------------------------------------
resource "azurerm_private_endpoint" "for_func" {
  name                = "${azurerm_function_app.main.name}-blob-private-endpoint"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.for_private_endpoint.id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.for_func.id]
  }

  private_service_connection {
    name                           = "FunctionPrivateLinkConnection"
    private_connection_resource_id = azurerm_function_app.main.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "for_func" {
  name                  = "for-func-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.for_func.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
